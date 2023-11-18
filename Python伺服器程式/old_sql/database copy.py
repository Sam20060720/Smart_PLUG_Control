import sqlite3
import os
import objects
if not os.path.exists("data"):
    os.makedirs("data")

conDEVICES = sqlite3.connect("data/dbDEVICES.db",check_same_thread=False) #裝置資料庫
curDEVICES = conDEVICES.cursor()
curDEVICES.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='DEVICES'") #裝置表
#device : id, addtime,  name, status, type, token ,lastupdate
if not curDEVICES.fetchone():
    curDEVICES.execute("CREATE TABLE DEVICES (id INTEGER PRIMARY KEY AUTOINCREMENT, addtime TEXT, name TEXT, type TEXT, token TEXT  ,lastupdate TEXT)")
    conDEVICES.commit()

conDEVICES_LOGS = sqlite3.connect("data/dbDEVICES_LOGS.db",check_same_thread=False) #裝置狀態紀錄資料庫
curDEVICES_LOGS = conDEVICES_LOGS.cursor()

conDEVICES_DATA = sqlite3.connect("data/dbDEVICES_DATA.db",check_same_thread=False) #裝置資料紀錄資料庫
curDEVICES_DATA = conDEVICES_DATA.cursor()

def getDevice(token,cur=curDEVICES,con=conDEVICES,curlog=curDEVICES_LOGS ,conlog=conDEVICES_LOGS): #取得裝置資料
    cur.execute("SELECT * FROM DEVICES WHERE token = ?",(token,))
    getcur = cur.fetchone()
    if getcur == None:
        return None

    status = None
    getlogs =  getDeviceLogs(token,cur=curlog,con=conlog)
    for i in getlogs:
        if i[1] in objects.devicestatus[getcur[3]]:
            status = i[1]
            break
    
    if status == None:
        status = objects.devicestatus[getcur[3]][0]

    if getcur:
        device = objects.device(*getcur,status)
        return device
    return None
    

def getDeviceLogs(token,cur=curDEVICES_LOGS,con=conDEVICES_LOGS): #取得裝置狀態紀錄
    cur.execute(f"SELECT name FROM sqlite_master WHERE type='table' AND name='DEVICE_LOGS_{token}'") #裝置狀態紀錄表
    if not cur.fetchone():
        cur.execute(f"CREATE TABLE DEVICE_LOGS_{token} (addtime TEXT, status TEXT, isread INTEGER)")
        con.commit()
        return []
    cur.execute(f"SELECT * FROM DEVICE_LOGS_{token}")
    return cur.fetchall()

def updateDeviceLogs(token,addtime,status,isread=0,cur=curDEVICES_LOGS,con=conDEVICES_LOGS): #更新裝置狀態紀錄
    cur.execute(f"INSERT INTO DEVICE_LOGS_{token} (addtime,status,isread) VALUES (?,?,?)",(addtime,status,isread))
    con.commit()
    return True


def getDeviceData(token,cur=curDEVICES_DATA,con=conDEVICES_DATA):
    cur.execute(f"SELECT name FROM sqlite_master WHERE type='table' AND name='DEVICE_DATA_{token}'") #裝置資料紀錄表 (用電...)
    if not cur.fetchone():
        cur.execute(f"CREATE TABLE DEVICE_DATA_{token} (addtime TEXT, data TEXT)")
        con.commit()
        return []
    cur.execute(f"SELECT * FROM DEVICE_DATA_{token}")
    return cur.fetchall()

def registerDevice(token,name,devtype,curdevice=curDEVICES,condevice=conDEVICES, curlog=curDEVICES_LOGS ,conlog=conDEVICES_LOGS,curdata=curDEVICES_DATA,condata=conDEVICES_DATA): #註冊裝置
    curdevice.execute("INSERT INTO DEVICES (addtime,name,type,token,lastupdate) VALUES (?,?,?,?,?)",(objects.getNowTime(),name,devtype,token,objects.getNowTime()))
    # curlog.execute( f"CREATE TABLE DEVICE_LOGS_{token} (addtime TEXT, status TEXT, isread INTEGER)")
    # curlog.execute(f"INSERT INTO DEVICE_LOGS_{token} (addtime,status,isread) VALUES (?,?,?)",(objects.getNowTime(),'Register',0))
    # curdata.execute(f"CREATE TABLE DEVICE_DATA_{token} (addtime TEXT, data TEXT)")
    condevice.commit()
    # conlog.commit()
    # condata.commit()

def updateDevice(token,name,status,cur=curDEVICES,con=conDEVICES,curlog=curDEVICES_LOGS ,conlog=conDEVICES_LOGS): #更新裝置資料
    old_device = getDevice(token)
    devtype = old_device.type
    # curlog.execute(f"INSERT INTO DEVICE_LOGS_{token} (addtime,status,isread) VALUES (?,?,?)",(objects.getNowTime(),status,0))
    # curlog.execute(f"DELETE FROM DEVICE_LOGS_{token} WHERE addtime < (SELECT addtime FROM DEVICE_LOGS_{token} ORDER BY addtime DESC LIMIT 1 OFFSET 100)")
    # cur.execute(f"UPDATE DEVICES SET lastupdate = ? WHERE token = ?",(objects.getNowTime(),token))
    con.commit()
    # conlog.commit()
    



def close():
    conDEVICES.commit()
    conDEVICES_LOGS.commit()
    conDEVICES_DATA.commit()
    conDEVICES.close()
    conDEVICES_LOGS.close()
    conDEVICES_DATA.close()
