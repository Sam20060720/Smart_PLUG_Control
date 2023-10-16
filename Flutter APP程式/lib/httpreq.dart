import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class HttpReq {
  BaseOptions option = BaseOptions(
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  );
  late Dio dio = Dio(option);

  String baseUrl = 'http://sam07205.synology.me:5555/api';
  late String reqtoken = '$baseUrl/reqtoken';
  late String getdevice = '$baseUrl/getdevice';
  late String getstat = '$baseUrl/getstat';
  late String setstat = '$baseUrl/setstat';
  late String line = '$baseUrl/line';
  late String regline = '$baseUrl/regline';
  late String settingpath = '$baseUrl/set';
  late String getsettingpath = '$baseUrl/getsetting';
  late String gethistory = '$baseUrl/gethistory';

  Future<dynamic> getReqToken(String code) async {
    FormData formData = FormData.fromMap({
      "code": code,
    });
    //wait 1s
    try {
      var response = await dio.post(reqtoken, data: formData);
      if (response.statusCode == 200) {
        if (response.data != "error") {
          Device thedevice = Device.fromJson(response.data);
          return thedevice;
        } else {
          return "error";
        }
      } else {
        // print(response.statusCode);
        return Device(type: "", token: "", lastupdate: "", status: "", setting: {});
      }
    } catch (e) {
      return "server error";
    }
  }

  Future<Device> getDevice(String token) async {
    //create formdata
    FormData formData = FormData.fromMap({
      "token": token,
    });

    var response = await dio.post(getdevice, data: formData);
    if (response.statusCode == 200) {
      if (response.data == "error") {
        //delay 1s
        return Future.delayed(const Duration(seconds: 1)).then((value) => getDevice(token));
      }

      Device thedevice = Device.fromJson(response.data);

      return thedevice;
    } else {
      // print(response.statusCode);
      return Device(type: "", token: "", lastupdate: "", status: "", setting: {});
    }
  }

  Future<dynamic> getStat(String token) async {
    //create formdata
    FormData formData = FormData.fromMap({
      "token": token,
    });
    try {
      var response = await dio.post(getstat, data: formData);
      if (response.statusCode == 200) {
        if (response.data == "error(not connected)") {
          return "OFFLINE";
        }
        List<Map<dynamic, dynamic>> statusHistoryMap = [];
        for (var i = 0; i < response.data["status_history"].length; i++) {
          statusHistoryMap.add(Map<dynamic, dynamic>.from(json.decode(response.data["status_history"][i])));
        }
        response.data["status_history"] = statusHistoryMap;

        return response.data;
      } else {
        // print(response.statusCode);
        return "OFFLINE";
      }
    } catch (e) {
      return "SERVER ERROR";
    }
  }

  Future<dynamic> setStat(String token, String stat) async {
    //create formdata
    FormData formData = FormData.fromMap({
      "token": token,
      "status": stat,
    });

    var response = await dio.post(setstat, data: formData);
    if (response.statusCode == 200) {
      if (response.data == "error(not connected)") {
        return "OFFLINE";
      }
      return response.data;
    } else {
      // print(response.statusCode);
      return "OFFLINE";
    }
  }

  Future<dynamic> testline(String userMid, String msg) async {
    //create formdata
    FormData formData = FormData.fromMap({
      "user_mid": userMid,
      'msg': msg,
    });

    var response = await dio.post(line, data: formData);
    if (response.statusCode == 200) {
      if (response.data == "error(not connected)") {
        return "OFFLINE";
      }
      return response.data;
    } else {
      // print(response.statusCode);
      return "OFFLINE";
    }
  }

  Future<dynamic> regLine(line_account user, Device device, {String msg = ""}) async {
    if (msg == "") {
      msg = "成功註冊${device.setting['name']}至您的Line帳號";
    }
    //create formdata
    FormData formData = FormData.fromMap({
      "user_mid": user.mid,
      'msg': msg,
      'device_token': device.token,
    });

    var response = await dio.post(regline, data: formData);
    if (response.statusCode == 200) {
      if (response.data == "error(not connected)") {
        return "OFFLINE";
      }
      return response.data;
    } else {
      // print(response.statusCode);
      return "OFFLINE";
    }
  }

  Future<dynamic> setting(String token, Map<String, String> settings) async {
    //create formdata
    FormData formData = FormData.fromMap(settings);
    formData.fields.add(MapEntry("token", token));

    var response = await dio.post(settingpath, data: formData);
    if (response.statusCode == 200) {
      if (response.data == "success") {
        return true;
      }
      return response.data;
    } else {
      return false;
    }
  }

  Future<dynamic> getHistory(String token, DateTimeRange rangetime) async {
    //create formdata
    FormData formData = FormData.fromMap({
      "token": token,
      "startdate": rangetime.start.millisecondsSinceEpoch ~/ 1000,
      "enddate": rangetime.end.millisecondsSinceEpoch ~/ 1000,
    });
    try {
      var response = await dio.post(gethistory, data: formData);
      if (response.statusCode == 200) {
        // ignore: non_constant_identifier_names
        List<Map<dynamic, dynamic>> HistoryMap = [];
        for (var i = 0; i < response.data["history"].length; i++) {
          HistoryMap.add(response.data["history"][i]);
          HistoryMap[i]["index"] = i;
        }
        // print(HistoryMap.length);

        return HistoryMap;
      } else {
        // print(response.statusCode);
        return "OFFLINE";
      }
    } catch (e) {
      // print(e);
      return "SERVER ERROR";
    }
  }

  Future<dynamic> getSetting(String token) async {
    //create formdata
    FormData formData = FormData.fromMap({
      "token": token,
    });
    try {
      var response = await dio.post(getsettingpath, data: formData);
      if (response.statusCode == 200) {
        if (response.data != "error") {
          return response.data;
        }
      }
    } catch (e) {
      return "error";
    }
    return "error";
  }
}

//an node has many devices
class Device {
  String type;
  String token;
  String lastupdate;
  String status;
  Map<dynamic, dynamic> rawdata = {};
  Map<dynamic, dynamic> setting = {};

  Device({
    required this.type,
    required this.token,
    required this.lastupdate,
    required this.status,
    required this.setting,
  });
  //with rawdata
  Device.withRawdata({
    required this.type,
    required this.token,
    required this.lastupdate,
    required this.status,
    required this.rawdata,
    required this.setting,
  });

  void setstatus(String status) {
    this.status = status;
  }

  factory Device.fromJson(Map<dynamic, dynamic> json) {
    if (json['rawdata'] == null) {
      return Device(type: json['type'], token: json['token'], lastupdate: json['lastupdate'], status: json['status'], setting: json['setting']);
    }
    return Device.withRawdata(type: json['type'], token: json['token'], lastupdate: json['lastupdate'], status: json['status'], rawdata: json['rawdata'], setting: json['setting']);
  }

  Map<dynamic, dynamic> toJson() => {'type': type, 'token': token, 'lastupdate': lastupdate, 'status': status, 'setting': setting};
}

// ignore: camel_case_types
class line_account {
  String mid;
  String name;
  String pictureUrl;
  String statusMessage;

  line_account({
    required this.mid,
    required this.name,
    required this.pictureUrl,
    required this.statusMessage,
  });

  factory line_account.fromJson(Map<String, dynamic> json) {
    return line_account(
      mid: json['mid'],
      name: json['displayName'],
      pictureUrl: json['pictureUrl'],
      statusMessage: json['statusMessage'],
    );
  }

  Map<String, dynamic> toJson() => {
        'mid': mid,
        'name': name,
        'pictureUrl': pictureUrl,
        'statusMessage': statusMessage,
      };
}
