from flask import Flask, render_template, request, jsonify, url_for, redirect, session
import database
import config
import objects
import random
import json
import time
import linenotify
from datetime import datetime, timedelta
from GLOBAL import *
from web import webapp
import util

app = Flask("App")
app.register_blueprint(webapp, url_prefix='/')

app.config['SECRET_KEY'] = config.SECRET_KEY
connectDevice = dict()
reqtoken = dict()

db = database.database('firebase.json', True)


@app.route("/api/register", methods=["POST"])
def register():
    gettoken = request.form.get('token')
    print(gettoken)
    gettype = request.form.get('type')
    if gettoken == None or gettype == None or len(gettoken) == 0 or len(gettype) == 0:
        return "error"
    else:
        if db.getDevice(gettoken) == None:
            if gettype not in objects.devicestatus:
                print(f"{gettoken} error(unknown type)")
                return "error(unknown type)"

            db.registerDevice(gettoken, gettype)
            connectDevice[gettoken] = db.getDevice(gettoken)
            connectDevice[gettoken].timeupdate()
            db.updateDeviceLogs(
                gettoken, 0,  connectDevice[gettoken].status, "Register to Server")
            print(f"{gettoken} Connect to Server")
            return getdevice()
        else:
            if connectDevice.get(gettoken) == None:
                connectDevice[gettoken] = db.getDevice(gettoken)
                connectDevice[gettoken].timeupdate()
                db.updateDeviceLogs(
                    gettoken, 0,  connectDevice[gettoken].status, "Connected to Server")
                print(f"{gettoken} Register to Server")
            return getdevice()


@app.route('/api/gentoken', methods=["GET"])
def genkey():
    return objects.genToken()


@app.route("/api/setstat", methods=["POST"])
def setstat():
    gettoken = request.form.get('token')
    getstatus = request.form.get('status')
    if gettoken == None or len(gettoken) == 0:
        return "error"
    else:
        if gettoken not in list(connectDevice):
            return "error (not connected)"
        else:
            getstatus = int(getstatus)
            # check status is valid
            objects.devicestatus[connectDevice[gettoken].type][getstatus]
            stat_from = objects.devicestatus[connectDevice[gettoken]
                                             .type][connectDevice[gettoken].status]
            stat_to = objects.devicestatus[connectDevice[gettoken].type][getstatus]
            db.updateDeviceLogs(
                gettoken, 1, connectDevice[gettoken].status, f"Status From {stat_from}({connectDevice[gettoken].status}) To {stat_to}({getstatus})")
            connectDevice[gettoken].update(getstatus)
            return "success"


@app.route("/api/reqdigit", methods=["POST"])
def reqdigit():
    gettoken = request.form.get('token')
    if gettoken == None or len(gettoken) == 0:
        return "error"
    else:
        if gettoken not in list(connectDevice):
            return "error(not connected)"
        else:
            getdigit = random.randint(100000, 999999)
            for i in reqtoken:
                if reqtoken[i][0] == gettoken:
                    del reqtoken[i]
                    reqtoken[getdigit] = (gettoken, objects.getNowTime())
                    return str(getdigit)
            # db.updateDeviceLogs(devicetoken, 0,  connectDevice[devicetoken].status, "Request Token")

            connectDevice[gettoken].timeupdate()
            reqtoken[getdigit] = (gettoken, objects.getNowTime())
            return str(getdigit)


@app.route("/api/reqtoken", methods=["POST"])
def reqtokenf():
    getcode = request.form.get('code')
    if getcode == None or len(getcode) == 0:
        return "error"
    else:
        try:
            getcode = int(getcode)
        except:
            return "error"
        if getcode not in list(reqtoken):
            return "error not in list"
        else:
            gettoken = reqtoken[getcode][0]
            tempdev = db.getDevice(gettoken)
            retdict = {
                "token": str(gettoken),
                "type": str(tempdev.type),
                "lastupdate": str(tempdev.lastupdate),
                "status": str(tempdev.status),
                'setting': tempdev.setting
            }
            return jsonify(retdict)


@app.route("/api/getstat", methods=["POST"])
def getstat():
    gettoken = request.form.get('token')
    if gettoken == None or len(gettoken) == 0:
        return "error"
    else:
        if gettoken not in list(connectDevice):
            return "error(not connected)"
        else:
            try:
                json_object = json.loads(connectDevice[gettoken].rawdata)
                json_object["status"] = connectDevice[gettoken].status
                json_object["status_history"] = connectDevice[gettoken].rawdata_history[0:10]
            except:
                return "empty"

            return jsonify(json_object)


@app.route("/api/update", methods=["POST"])
def update():
    gettoken = request.form.get('token')
    getdata = request.form.get('data')

    if gettoken == None or len(gettoken) == 0 or getdata == None:
        return "error"
    else:
        if gettoken not in list(connectDevice):
            return "error(not connected)"
        else:
            connectDevice[gettoken].timeupdate()
            connectDevice[gettoken].rawdata = getdata
            if len(connectDevice[gettoken].rawdata_history) <= 60:
                connectDevice[gettoken].rawdata_history.append(getdata)
            else:
                connectDevice[gettoken].rawdata_history.pop(60)
                connectDevice[gettoken].rawdata_history.insert(0, getdata)

            if connectDevice[gettoken].cache["datacount"] < 60:

                connectDevice[gettoken].cache["datacount"] += 1
            else:
                history_list = []
                average_history = {}

                for hisi in connectDevice[gettoken].rawdata_history:
                    hisi = json.loads(hisi)
                    history_list.append(hisi)
                    for item in objects.deviceCalc[connectDevice[gettoken].type]:
                        if item not in average_history:
                            average_history[item] = 0
                        average_history[item] += hisi[item]

                for item in objects.deviceCalc[connectDevice[gettoken].type]:
                    average_history[item] /= len(history_list)
                    average_history[item] = round(average_history[item], 2)

                db.updateDeviceHistory(gettoken, average_history)
                connectDevice[gettoken].cache["datacount"] = 0

            if connectDevice[gettoken].cache["needupdate"]:
                connectDevice[gettoken].cache["needupdate"] = False
                return "UPD"

            return str(connectDevice[gettoken].status)


@app.route("/api/getdevice", methods=["POST"])
def getdevice():
    gettoken = request.form.get('token')
    if gettoken == None or len(gettoken) == 0:
        return "error"
    else:
        tempdev = db.getDevice(gettoken)
        if tempdev:
            retdict = {
                "token": str(gettoken),
                "type": str(tempdev.type),
                "lastupdate": str(tempdev.lastupdate),
                "status": str(tempdev.status),
                'setting': tempdev.setting
            }
            return jsonify(retdict)
        else:
            return "error"


@app.route('/api/set', methods=["POST"])
def setsetting():
    gettoken = request.form.get('token')
    device = db.getDevice(gettoken)
    if device == None:
        return "error"
    settinglist = objects.deviceDefaultSetting[device.type].keys()
    getsetting = {}
    for setting in settinglist:
        getrest = request.form.get(setting)
        if getrest != None:
            getsetting[setting] = getrest

    if connectDevice.get(gettoken):
        connectDevice[gettoken].cache["needupdate"] = True

    if db.setDeviceSetting(gettoken, getsetting):
        return "success"
    else:
        return "error"


@app.route('/api/getsetting', methods=["POST"])
def getsetting():
    gettoken = request.form.get('token')
    device = db.getDevice(gettoken)
    if device == None:
        return "error"
    # db.getDeviceSetting
    settinglist = objects.deviceDefaultSetting[device.type].keys()
    getsetting = {}
    for setting in settinglist:
        getsetting[setting] = device.setting.get(setting)

    return jsonify(getsetting)


@app.route('/api/regline', methods=["POST"])
def line_send():
    user_mid = request.form.get('user_mid')
    msg = request.form.get('msg')
    device_token = request.form.get('device_token')
    print(user_mid, msg, device_token)

    linenotify.send_message_to_friend(user_mid, msg)
    db.regLine(device_token, user_mid)

    return "ok"


@app.route('/api/unregline', methods=["POST"])
def line_unreg():
    device_token = request.form.get('device_token')
    db.unregLine(device_token)

    return "ok"


@app.route('/api/gethistory', methods=["POST"])
def getHistory():
    gettoken = request.form.get('token')
    start_date = request.form.get(
        'startdate')
    end_date = request.form.get(
        'enddate')
    if gettoken == None or start_date == None or end_date == None:
        return "error"
    else:
        device = db.getDevice(gettoken)
        if device == None:
            return "error"
        try:
            start_date = int(start_date)
            end_date = int(end_date)
            print(start_date,end_date)

        except:
            return "error"

        # to datetime
        start_time = datetime.fromtimestamp(start_date)
        end_time = datetime.fromtimestamp(end_date)
        end_time = end_time + timedelta(days = 1)
        start_time.replace(hour=0, minute=0, second=0)
        end_time.replace(hour=23, minute=59, second=59)
        time_range = (end_time - start_time).days 

        

        # to stamp
        start_date_int = int(start_time.timestamp())
        end_date_int = int(end_time.timestamp())

        # 計算時間間隔數量
        if time_range <= 5:
            interval_size_seconds = 3600 * time_range  # 1小時 * 天數
        else:
            interval_size_seconds = int((end_date_int-start_date_int) / (24+abs(8 * (time_range - 5))))
        
        

        history = db.getHistoryInRange(gettoken, start_date_int, end_date_int)
        interval_averages = util.calculate_averages_in_intervals(
            history, interval_size_seconds, start_time, end_time)

        return jsonify({"history": interval_averages})


@app.route('/api')
def indexapi():
    return 'alive'


def updateDeviceStatus():
    for devicetoken in list(connectDevice):
        if connectDevice[devicetoken].istimeout():
            print('device: %s is timeout' % devicetoken)
            db.updateDeviceLogs(
                devicetoken, 0,  connectDevice[devicetoken].status, "Connect Lost")
            connectDevice.pop(devicetoken)

    for reqtokenid in list(reqtoken):
        if objects.getNowTime() - reqtoken[reqtokenid][1] > 60:
            print('reqtoken: %s is timeout' % reqtokenid)
            del reqtoken[reqtokenid]


def main():
    rt = objects.RepeatedTimer(5, updateDeviceStatus)
    if __name__ == "__main__":
        try:
            rt.start()
            app.run("0.0.0.0", port=5000, debug=True)
        finally:
            rt.stop()
            print("exit")
            exit()


if __name__ == "__main__":
    main()
