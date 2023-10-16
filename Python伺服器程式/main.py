from flask import Flask,render_template,request,jsonify
import database
import config
import objects
import random
import json
import time

app = Flask("App")
app.config['SECRET_KEY'] = config.SECRET_KEY
connectDevice = dict()
reqtoken = dict()

@app.route("/api/register",methods=["POST"])
def register():
    gettoken = request.form.get('token')
    getname = request.form.get('name')
    gettype = request.form.get('type')
    print(gettoken,getname,gettype)
    if gettoken == None or getname == None or gettype == None or len(gettoken) == 0 or len(getname) == 0 or len(gettype) == 0:
        return "error"
    else:
        if database.getDevice(gettoken) == None:
            if gettype not in objects.devicestatus:
                print("error(unknown type)")
                return "error(unknown type)"
            database.registerDevice(gettoken,getname,gettype)
            connectDevice[gettoken] = database.getDevice(gettoken)
            connectDevice[gettoken].timeupdate()
            print("register success")
            return "success"
        else:
            connectDevice[gettoken] = database.getDevice(gettoken)
            connectDevice[gettoken].timeupdate()
            print("registed")
            return "registed"
    return "error" #unknow error

@app.route('/api/gentoken',methods=["GET"])
def genkey():
    return objects.genToken()


@app.route("/api/setstat",methods=["POST"])
def setstat():
    gettoken = request.form.get('token')
    getstatus = request.form.get('status')
    if gettoken == None or len(gettoken) == 0:
        return "error"
    else:
        if gettoken not in list(connectDevice):
            return "error(not connected)"
        else:
            connectDevice[gettoken].update(getstatus)
            database.updateDevice(gettoken,connectDevice[gettoken].name,getstatus)
            return "success"

@app.route("/api/reqdigit",methods=["POST"])
def reqdigit():
    gettoken = request.form.get('token')
    if gettoken == None or len(gettoken) == 0:
        return "error"
    else:
        if gettoken not in list(connectDevice):
            return "error(not connected)"
        else:
            getdigit = random.randint(100000,999999)
            for i in reqtoken:
                if reqtoken[i][0] == gettoken:
                    del reqtoken[i]
                    reqtoken[getdigit] = (gettoken,objects.getNowTime())
                    return str(getdigit)
            connectDevice[gettoken].timeupdate()
            reqtoken[getdigit] = (gettoken,objects.getNowTime())
            return str(getdigit)

@app.route("/api/reqtoken",methods=["POST"])
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
            while True:
                try:
                    tempdev = database.getDevice(gettoken)
                    break
                except:
                    time.sleep(0.1) 
            retdict = {
                "token":str(gettoken),
                "name":str(tempdev.name),
                "type":str(tempdev.type),
                "id" :str( tempdev.id),
                "addtime":str( tempdev.addtime),
                "lastupdate" :str( tempdev.lastupdate),
                "status":str(tempdev.status)
            }
            return jsonify(retdict)
            
            

    
@app.route("/api/getstat",methods=["POST"])
def getstat():
    gettoken = request.form.get('token')
    if gettoken == None or len(gettoken) == 0:
        return "error"
    else:
        if gettoken not in list(connectDevice):
            return "error(not connected)"
        else:


            json_object = json.loads(connectDevice[gettoken].rawdata)
            #add status to json
            json_object["status"] = connectDevice[gettoken].status
            

            return jsonify(json_object) 

@app.route("/api/update",methods=["POST"])
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
            # print(getdata)
            return connectDevice[gettoken].status

@app.route("/api/getdevice",methods=["POST"])
def getdevice():
    gettoken = request.form.get('token')
    if gettoken == None or len(gettoken) == 0:
        return "error"
    else:
        while True:
            try:
                tempdev = database.getDevice(gettoken)
                break
            
            except:
                time.sleep(0.1) 
        retdict = {
            "token":str(gettoken),
            "name":str(tempdev.name),
            "type":str(tempdev.type),
            "id" :str( tempdev.id),
            "addtime":str( tempdev.addtime),
            "lastupdate" :str( tempdev.lastupdate),
            "status":str(tempdev.status)
        }
        return jsonify(retdict)

@app.route('/api')
def indexapi():
    return 'alive'

@app.route('/')
def index():
    return render_template('index.html')

def updateDeviceStatus():
    
    for devicetoken in list(connectDevice):
        print(connectDevice[devicetoken].getdict())
        if connectDevice[devicetoken].istimeout():
            print('device: %s is timeout' % devicetoken)
            del connectDevice[devicetoken]
    
    for reqtokenid in list(reqtoken):
        if objects.getNowTime() - reqtoken[reqtokenid][1] > 60:
            print('reqtoken: %s is timeout' % reqtokenid)
            del reqtoken[reqtokenid]


rt = objects.RepeatedTimer(10,updateDeviceStatus)

if __name__ == "__main__":
    try: 
        rt.start()
        app.run ("0.0.0.0",port=5000,debug=True)

    finally:
        print("finally")
        rt.stop()
        database.close()
        print("exit")
        exit()