from threading import Timer
import time
import json


class RepeatedTimer(object):
    def __init__(self, interval, function, *args, **kwargs):
        self._timer = None
        self.interval = interval
        self.function = function
        self.args = args
        self.kwargs = kwargs
        self.is_running = False
        self.start()

    def _run(self):
        self.is_running = False
        self.start()
        self.function(*self.args, **self.kwargs)

    def start(self):
        if not self.is_running:
            self._timer = Timer(self.interval, self._run)
            self._timer.start()
            self.is_running = True

    def stop(self):
        self._timer.cancel()
        self.is_running = False


class device(object):
    def __init__(self, devtype, token, status, setting):
        # addtime,name,type,token,lastupdate
        self.type = devtype
        self.token = token
        self.lastupdate = time.time()
        self.status = status
        self.rawdata = None
        self.rawdata_history = []
        self.setting = setting
        self.cache = {"needupdate": False, "datacount": 0}

    def update(self, status=None):
        self.status = status if status != None else self.status
        self.lastupdate = time.time()

    def timeupdate(self):
        self.lastupdate = time.time()

    def istimeout(self, timeout=10):  # 10秒
        timelast = int(self.lastupdate)
        if int(time.time()) - timelast > timeout:
            return True
        return False

    def getsave(self):
        return {
            "token": str(self.token),
            "type": str(self.type),
            "lastupdate": str(self.lastupdate),
            "status": str(self.status),
            "setting": self.setting,
            'rawdata': self.rawdata,
            'rawdata_history': self.rawdata_history,
            'cache': self.cache
        }

    # return dict
    def getdict(self):
        return {
            "token": str(self.token),
            "type": str(self.type),
            "lastupdate": str(self.lastupdate),
            "status": str(self.status),
            "setting": self.setting
        }


def getNowTime():
    # get unix time and convert to int
    return int(time.time())


def genToken():
    # use random String include 0-9 a-z A-Z
    import random
    import string
    return ''.join(random.choice(string.ascii_letters + string.digits) for _ in range(64))


devicestatus = {
    "PLUG": ["ON", "OFF"],
    "PLUGDUAL": ["ONON", "OFFOFF", "ONOFF", "OFFON"],
}

deviceDefaultSetting = {
    "PLUG": {"status": "0",
             "name": "PLUG",
             "safeMinTemp": "20",
             "safeMaxTemp": "60",
             "safeMinHumid": "0",
             "safeMaxHumid": "100",
             "safeMinVoltage": "80",
             "safeMaxVoltage": "250",
             "safeMaxWatt": "1000"},
    "PLUGDUAL": {
        "status": "0",
        "name": "PLUG (DUAL)",
        "safeMinTemp": "20",
        "safeMaxTemp": "60",
        "safeMinVoltage": "80",
        "safeMaxVoltage": "250",
        "safeMaxWatt": "1000"},
}

deviceCalc = {
    "PLUG": [''],
    "PLUGDUAL": ['voltage', 'current1', 'current2', 'temp']
}
