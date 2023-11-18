import firebase_admin
from firebase_admin import credentials
import objects
import time
from datetime import datetime, timezone, timedelta
import linenotify
import json
import mock
from flask import Flask, render_template, request
import google.auth.credentials
import os
from google.cloud import firestore

class database:
    def __init__(self, jsonfile, isemu=False, emuurl="192.168.50.50:8080"):
        if not isemu:
            from firebase_admin import firestore
            cred = credentials.Certificate(jsonfile)  # 引用私密金鑰
            firebase_admin.initialize_app(cred)
            self.db = firestore.client()  # 初始化firestore
            self.DEVICES_ref = self.db.collection('DEVICES')  # 取得DEVICES集合
            self.DEVICES_LOGS_ref = self.db.collection("DEVICES_LOGS")
            self.DEVICES_DATA_ref = self.db.collection("DEVICES_DATA")
            print("Firebase Initializing")
        else:
            from google.cloud import firestore
            os.environ["FIRESTORE_EMULATOR_HOST"] = emuurl
            os.environ["FIRESTORE_PROJECT_ID"] = "smart_plug"

            cred = mock.Mock(spec=google.auth.credentials.Credentials)
            self.db = firestore.Client(credentials=cred)
            self.DEVICES_ref = self.db.collection('DEVICES')
            self.DEVICES_LOGS_ref = self.db.collection("DEVICES_LOGS")
            self.DEVICES_DATA_ref = self.db.collection("DEVICES_DATA")

            # self.updateDeviceLogs("test", 0, 0, "Device Registered")

    def getDevice(self, token):  # 取得裝置資料
        doc_ref = self.DEVICES_ref.document(token)
        doc = doc_ref.get()
        if doc.exists:
            devdict = doc.to_dict()

            # devdict['status'] = 0
            # get last status by docs in index (token/log/xxxx/xx/xx/logs/)
            now = datetime.now()
            nowtime = int(datetime.timestamp(now))

            doc_device_log_ref = self.DEVICES_LOGS_ref \
                .document(token).collection("logs").where('time', '<=', nowtime) \
                .order_by('time', direction=firestore.Query.DESCENDING).limit(1).stream()

            for doc in doc_device_log_ref:
                devdict['status'] = doc.to_dict()['status']

            devobj = objects.device(
                devdict['devicetype'], devdict['token'], devdict['status'], devdict['setting'])
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
        nowtime = int(datetime.timestamp(now))

        doc_device_log_ref = self.DEVICES_LOGS_ref \
            .document(token).collection("logs").document(str(nowtime))

        doc_device_log_ref.set({
            'time': nowtime,
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
        nowtime = int(datetime.timestamp(now))

        doc_device_data_ref = self.DEVICES_DATA_ref \
            .document(token).collection("data").document(str(nowtime))

        setdata = {'time': int(datetime.timestamp(now))}

        setdata.update(rawdata)

        doc_device_data_ref.set(setdata)

    def getHistoryInRange(self, token, start_date, end_date):

        doc_device_data_ref = self.DEVICES_DATA_ref \
            .document(token).collection("data") \
            .where('time', '>=', start_date) \
            .where('time', '<=', end_date) \
            .order_by('time', direction=firestore.Query.ASCENDING) \
            .stream()

        data_dict = {}
        for doc in doc_device_data_ref:
            data_dict[doc.id] = doc.to_dict()
        return data_dict

    def getLogsInRange(self, token, start_date, end_date):

        doc_device_log_ref = self.DEVICES_LOGS_ref \
            .document(token).collection("logs") \
            .where('time', '>=', start_date) \
            .where('time', '<=', end_date) \
            .order_by('time', direction=firestore.Query.ASCENDING) \
            .stream()

        logs_dict = {}
        for doc in doc_device_log_ref:
            logs_dict[doc.id] = doc.to_dict()
        return logs_dict

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

    def unregLine(self, token, line_mid):
        doc_device_ref = self.DEVICES_ref.document(token)
        # use list to store line_mid
        doc_device_ref.update({
            'line_mid': firestore.ArrayRemove([line_mid])
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
    # db = database("firebase.json")
    db = database('firebase.json', True)
    while True:
        inp = input(
            "1.查詢裝置\n2.查詢裝置資訊(區間)\n3.列出裝置\ndelete.刪除裝置 \ncleandb.清空資料庫\nq.離開\n:")
        if inp == "1":
            token = input("請輸入裝置token:")
            dev = db.getDevice(token)
            if dev != None:
                print(dev.name)
                print(dev.type)
            else:
                print("裝置不存在")
        elif inp == "2":
            if input("1.查詢裝置資訊\n2.查詢裝置歷史資料\n:") == "1":

                token = input("請輸入裝置token:")
                start_date = input("請輸入起始日期(格式:2021-01-01):")
                end_date = input("請輸入結束日期(格式:2021-01-01):")
                start_date = datetime.strptime(start_date, '%Y-%m-%d')
                end_date = datetime.strptime(end_date, '%Y-%m-%d')
                logs_dict = db.getLogsInRange(token, start_date, end_date)
                end_date += timedelta(days=1)  # 包含結束日期當天的目錄

                start_date = int(datetime.timestamp(start_date))
                end_date = int(datetime.timestamp(end_date))

                for key in logs_dict:
                    print(logs_dict[key])
            else:
                token = input("請輸入裝置token:")
                start_date = input("請輸入起始日期(格式:2021-01-01):")
                end_date = input("請輸入結束日期(格式:2021-01-01):")
                # to time stamp
                start_date = datetime.strptime(start_date, '%Y-%m-%d')
                end_date = datetime.strptime(end_date, '%Y-%m-%d')

                end_date += timedelta(days=1)

                start_date = int(datetime.timestamp(start_date))
                end_date = int(datetime.timestamp(end_date))

                parsed = []
                retlist = {}
                history = db.getHistoryInRange(token, start_date, end_date)
                print(history)

                # startdate = datetime.datetime.strptime(startdate, '%Y-%m-%d')
                # startdate_stramp = datetime.datetime.timestamp(startdate)
                # enddate = datetime.datetime.strptime(enddate, '%Y-%m-%d')
                # enddate = enddate + datetime.timedelta(days=1)
                # enddate_stramp = datetime.datetime.timestamp(enddate)
                # daydiff = abs((enddate - startdate).days)

                # if daydiff <= 5:
                #     var_diff = daydiff * 24
                # else:
                #     var_diff = 24 * 5
                #     var_diff += abs(8 * (daydiff - 5))

                # # var_diff 為小時 ，轉換成時間戳記單位
                # var_diff = var_diff * 60 * 60

                # for i in parsed:
                #     nowindex = (startdate_stramp-i['time'])//var_diff
                #     try:
                #         retlist[nowindex].append(i)
                #     except:
                #         retlist[nowindex] = [i]
                # print(retlist)

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
