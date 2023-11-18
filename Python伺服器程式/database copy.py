import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
import objects
import time
from datetime import datetime, timezone, timedelta
import linenotify


class database:
    def __init__(self, jsonfile):
        cred = credentials.Certificate(jsonfile)  # 引用私密金鑰
        firebase_admin.initialize_app(cred)
        self.db = firestore.client()  # 初始化firestore
        self.DEVICES_ref = self.db.collection('DEVICES')  # 取得DEVICES集合
        self.DEVICES_LOGS_ref = self.db.collection("DEVICES_LOGS")
        self.DEVICES_DATA_ref = self.db.collection("DEVICES_DATA")
        print("Firebase Initializing")

    def getDevice(self, token):  # 取得裝置資料
        doc_ref = self.DEVICES_ref.document(token)
        doc = doc_ref.get()
        if doc.exists:
            devdict = doc.to_dict()

            # devdict['status'] = 0
            # get last status by docs in index (token/log/xxxx/xx/xx/logs/)
            doc_device_log_ref = self.DEVICES_LOGS_ref \
                .document(token).collection("logs") \
                .document(str(datetime.now().year)).collection(str(datetime.now().month).zfill(2)).document(str(datetime.now().day).zfill(2)) \
                .collection("logs").order_by("time", direction=firestore.Query.DESCENDING).limit(1)

            doc = doc_device_log_ref.get()
            print(doc)
            if len(doc) == 0:
                devdict['status'] = 0
            else:
                devdict['status'] = doc[0].to_dict()['status']

            devobj = objects.device(
                devdict['devicetype'], devdict['token'], devdict['status'], devdict['setting'])
            print(devobj.setting)
            return devobj
        else:
            return None

    def registerDevice(self, token, devicetype):  # 註冊裝置
        doc_device_ref = self.DEVICES_ref.document(token)
        doc_device_ref.set({
            'devicetype': devicetype,
            'token': token,
            'addtime': int(time.time()),
            'setting': objects.deviceDefaultSetting[devicetype],
        })
        self.updateDeviceLogs(token, 0, 0, "Device Registered")

    def updateDeviceLogs(self, token, conn_status, status, msg):
        now = datetime.now()
        year = str(now.year)
        month = str(now.month).zfill(2)
        day = str(now.day).zfill(2)
        hour_minute_second = now.strftime('%H%M%S')

        doc_device_log_ref = self.DEVICES_LOGS_ref \
            .document(token).collection("logs") \
            .document(year).collection(month).document(day) \
            .collection("logs").document(hour_minute_second)

        doc_device_log_ref.set({
            'time': int(datetime.timestamp(now)),
            'conn_status': conn_status,
            'status': status,
            'msg': msg,
            'isRead': False
        })

        doc_device_ref = self.DEVICES_ref.document(token)
        doc = doc_device_ref.get()

        devdict = doc.to_dict()
        line_mid_list = devdict.get('line_mid')
        if line_mid_list == None:
            return

        devicename = devdict['setting']['name']

        for line_mid in line_mid_list:
            sendmsg = f"[{devicename}] {msg}"
            linenotify.send_message_to_friend(line_mid, sendmsg)

    def updateDeviceHistory(self, token, rawdata):
        now = datetime.now()
        year = str(now.year)
        month = str(now.month).zfill(2)
        day = str(now.day).zfill(2)
        hour_minute_second = now.strftime('%H%M%S')

        doc_device_data_ref = self.DEVICES_DATA_ref \
            .document(token).collection("data") \
            .document(year).collection(month).document(day) \
            .collection("data").document(hour_minute_second)

        doc_device_data_ref.set({
            'time': int(datetime.timestamp(now)),
            'data': rawdata,
        })

    def getHistoryInRange(self, token, start_date, end_date):
        end_date += timedelta(days=1)
        query_directories = []

        for year in range(start_date.year, end_date.year+1):
            if year == start_date.year:
                if start_date.year == end_date.year:
                    if end_date.month - start_date.month > 6:
                        query_directories.append(f"{year}")
                    else:
                        for month in range(start_date.month, end_date.month):
                            query_directories.append(
                                f"{year}/{str(month).zfill(2)}")
                else:
                    if 12 - start_date.month > 6:
                        query_directories.append(f"{year}")
                    else:
                        for month in range(start_date.month, 13):
                            query_directories.append(
                                f"{year}/{str(month).zfill(2)}")
            elif year == end_date.year:
                if end_date.month > 6:
                    query_directories.append(f"{year}")
                else:
                    for month in range(1, end_date.month + 1):
                        query_directories.append(
                            f"{year}/{str(month).zfill(2)}")
            else:
                query_directories.append(f"{year}")

        resault = {}

        print(query_directories)

        for directory in query_directories:
            # 只有年，取得該年所有月份，並且每個月份都取得該月份所有日期
            if len(directory.split("/")) == 1:
                directory_query = self.DEVICES_DATA_ref\
                    .document(token).collection("data")\
                    .document(directory)
                for month in directory_query.collections():
                    # month is CollectionReference
                    for day in month.list_documents():
                        date_query = day.collection("data").order_by(
                            "time", direction=firestore.Query.DESCENDING)
                        for dayq in date_query.get():
                            data = dayq.to_dict()
                            resault[data['time']] = data

            # 有年有月，取得該月份所有日期
            elif len(directory.split("/")) == 2:
                directory_query = self.DEVICES_DATA_ref\
                    .document(token).collection("data")\
                    .document(directory.split("/")[0]).collection(directory.split("/")[1])
                for day in directory_query.list_documents():
                    date_query = day.collection("data").order_by(
                        "time", direction=firestore.Query.DESCENDING)
                    for dayq in date_query.get():
                        data = dayq.to_dict()
                        resault[data['time']] = data

        # sort
        resault = dict(
            sorted(resault.items(), key=lambda item: int(item[0]), reverse=False))

        # filter
        resault = {k: v for k, v in resault.items(
        ) if start_date.timestamp() <= int(k) <= end_date.timestamp()}

        return resault

    def getLogsInRange(self, token, start_date, end_date):
        end_date += timedelta(days=1)  # 包含結束日期當天的目錄
        query_directories = []

        for year in range(start_date.year, end_date.year+1):
            if year == start_date.year:
                if start_date.year == end_date.year:
                    if end_date.month - start_date.month > 6:
                        query_directories.append(f"{year}")
                    else:
                        for month in range(start_date.month, end_date.month):
                            query_directories.append(
                                f"{year}/{str(month).zfill(2)}")
                else:
                    if 12 - start_date.month > 6:
                        query_directories.append(f"{year}")
                    else:
                        for month in range(start_date.month, 13):
                            query_directories.append(
                                f"{year}/{str(month).zfill(2)}")
            elif year == end_date.year:
                if end_date.month > 6:
                    query_directories.append(f"{year}")
                else:
                    for month in range(1, end_date.month + 1):
                        query_directories.append(
                            f"{year}/{str(month).zfill(2)}")
            else:
                query_directories.append(f"{year}")

        resault = {}

        print(query_directories)

        for directory in query_directories:
            # 只有年，取得該年所有月份，並且每個月份都取得該月份所有日期
            if len(directory.split("/")) == 1:
                directory_query = self.DEVICES_LOGS_ref\
                    .document(token).collection("logs")\
                    .document(directory)
                for month in directory_query.collections():
                    # month is CollectionReference
                    for day in month.list_documents():
                        date_query = day.collection("logs").order_by(
                            "time", direction=firestore.Query.DESCENDING)
                        for dayq in date_query.get():
                            data = dayq.to_dict()
                            resault[data['time']] = data

            # 有年有月，取得該月份所有日期
            elif len(directory.split("/")) == 2:
                directory_query = self.DEVICES_LOGS_ref\
                    .document(token).collection("logs")\
                    .document(directory.split("/")[0]).collection(directory.split("/")[1])
                for day in directory_query.list_documents():
                    date_query = day.collection("logs").order_by(
                        "time", direction=firestore.Query.DESCENDING)
                    for dayq in date_query.get():
                        data = dayq.to_dict()
                        resault[data['time']] = data

        # sort
        resault = dict(
            sorted(resault.items(), key=lambda item: int(item[0]), reverse=False))

        # filter
        resault = {k: v for k, v in resault.items(
        ) if start_date.timestamp() <= int(k) <= end_date.timestamp()}

        return resault

    def setDeviceSetting(self, token, setting):
        doc_device_ref = self.DEVICES_ref.document(token)
        doc = doc_device_ref.get()
        if doc.exists:
            devdict = doc.to_dict()
            old_setting = devdict['setting']
            print(old_setting, setting)
            for key in setting:
                old_setting[key] = setting[key]
            doc_device_ref.update({
                'setting': old_setting
            })
            return True
        else:
            return False

    def regLine(self, token, line_mid):
        doc_device_ref = self.DEVICES_ref.document(token)
        # use list to store line_mid
        doc_device_ref.update({
            'line_mid': firestore.ArrayUnion([line_mid])
        })

    def getLine(self, token):
        doc_device_ref = self.DEVICES_ref.document(token)
        doc = doc_device_ref.get()
        if doc.exists:
            devdict = doc.to_dict()
            return devdict['line_mid']
        else:
            return None


if __name__ == "__main__":
    db = database("firebase.json")
    while True:
        inp = input(
            "1.查詢裝置\n2.查詢裝置紀錄(區間)\n3.列出裝置\ndelete.刪除裝置 \ncleandb.清空資料庫\nq.離開\n:")
        if inp == "1":
            token = input("請輸入裝置token:")
            dev = db.getDevice(token)
            if dev != None:
                print(dev.name)
                print(dev.type)
            else:
                print("裝置不存在")
        elif inp == "2":
            token = input("請輸入裝置token:")
            start_date = input("請輸入起始日期(格式:2021-01-01):")
            end_date = input("請輸入結束日期(格式:2021-01-01):")
            start_date = datetime.strptime(start_date, '%Y-%m-%d')
            end_date = datetime.strptime(end_date, '%Y-%m-%d')
            logs_dict = db.getLogsInRange(token, start_date, end_date)
            for key in logs_dict:
                print(logs_dict[key])
        elif inp == "3":
            docs = db.DEVICES_ref.stream()
            for doc in docs:
                print(f'{doc.id} \n\t=> {doc.to_dict()}')
        elif inp == "delete":
            token = input("請輸入裝置token:")
            db.DEVICES_ref.document(token).delete()
            db.DEVICES_LOGS_ref.document(token).delete()
            db.DEVICES_DATA_ref.document(token).delete()
        elif inp == "cleandb":
            docs = db.DEVICES_ref.stream()
            for doc in docs:
                doc.reference.delete()
            docs = db.DEVICES_LOGS_ref.stream()
            for doc in docs:
                doc.reference.delete()
            docs = db.DEVICES_DATA_ref.stream()
            for doc in docs:
                doc.reference.delete()
            print("資料庫已清空")
        elif inp == "q":
            exit()
        print("---------------------------------")
