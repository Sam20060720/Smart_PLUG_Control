import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:smart_plug_control/httpreq.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:switcher_xlive/switcher_xlive.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_plug_control/home.dart';
import 'package:smart_plug_control/line.dart';
import 'package:flutter_spinner_time_picker/flutter_spinner_time_picker.dart';
import "package:intl/intl.dart";

// ignore: camel_case_types
class devicePage extends StatefulWidget {
  const devicePage({Key? key, required this.device, required this.deviceCard}) : super(key: key);

  final Device device;
  final Widget deviceCard;

  @override
  // ignore: library_private_types_in_public_api
  _devicePageState createState() => _devicePageState();
}

// ignore: camel_case_types
class _devicePageState extends State<devicePage> {
  bool showlivechart = true;
  bool showhistorychart = false;
  int nowfhartpage = 0;
  int nowhistorypage = 0;
  late double safeMinTemp = widget.device.setting['safeMinTemp'] == null ? 20 : double.tryParse(widget.device.setting['safeMinTemp']) ?? 20;
  late double safeMaxTemp = widget.device.setting['safeMaxTemp'] == null ? 80 : double.tryParse(widget.device.setting['safeMaxTemp']) ?? 80;
  late double safeMinVoltage = widget.device.setting['safeMinVoltage'] == null ? 80 : double.tryParse(widget.device.setting['safeMinVoltage']) ?? 80;
  late double safeMaxVoltage = widget.device.setting['safeMaxVoltage'] == null ? 250 : double.tryParse(widget.device.setting['safeMaxVoltage']) ?? 250;
  late double safeMaxWatt = widget.device.setting['safeMaxWatt'] == null ? 1500 : double.tryParse(widget.device.setting['safeMaxWatt']) ?? 1500;

  late Timer timer;
  // ignore: non_constant_identifier_names
  late Timer timer_setting;
  var initialDate = DateTime.now();
  var initialDateRange = DateTimeRange(start: DateTime.now().subtract(const Duration(days: 7)), end: DateTime.now());
  late ZoomPanBehavior _zoomPanBehavior;
  late List<Map<dynamic, dynamic>> statusLiveMap = widget.device.rawdata['status_history'] ?? [];
  late List<Map<dynamic, dynamic>> statusHistoryMap = [];
  final TextEditingController nameinput = TextEditingController();

  final TextEditingController passwordoldinput = TextEditingController();
  final TextEditingController passwordnewinput = TextEditingController();
  final TextEditingController passwordverifyinput = TextEditingController();
  late String imgrandom = "assets/images/background/bg${Random().nextInt(7) + 1}.jpg";
  late int _selectedIndex = 0;

  late List<timestate> timerlist = [
    timestate(status: 0, time: TimeOfDay.now()),
  ];

  bool showpassword = false;
  bool serverError = false;

  //init now date range
  DateTimeRange nowDateRange = DateTimeRange(start: DateTime.now(), end: DateTime.now());
  @override
  void initState() {
    _zoomPanBehavior = ZoomPanBehavior(
      // Enables pinch zooming
      enablePinching: true,
      enablePanning: true,
      //only allow x zoom
      zoomMode: ZoomMode.x,
      //minimum zoom
    );
    timer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      // update device status
      HttpReq().getStat(widget.device.token).then((devstat) {
        if (devstat == "SERVER ERROR") {
          setState(() {
            widget.device.status = "OFFLINE";
          });
        } else {
          if (mounted) {
            setState(() {
              if (devstat.runtimeType != String) {
                widget.device.rawdata = devstat;
                widget.device.status = "ONLINE";
              } else {
                widget.device.status = "OFFLINE";
              }
            });
          }
        }
      });

      update_livechart();
    });
    //update setting
    timer_setting = Timer.periodic(const Duration(milliseconds: 5000), (timer) {
      HttpReq().getSetting(widget.device.token).then((setting) {
        if (setting == "error") {
        } else {
          if (widget.device.setting != setting) {
            widget.device.setting = setting;
            SharedPreferences.getInstance().then((SharedPreferences sharedPreference) {
              List<String> listString = sharedPreference.getStringList('devices') ?? [];
              listString.removeWhere((element) => json.decode(element)['token'] == widget.device.token);
              listString.add(json.encode(widget.device.toJson()));
              sharedPreference.setStringList('devices', listString);
            });
          }
        }
      });
    });
    super.initState();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // ignore: non_constant_identifier_names
  void update_livechart() {
    if (widget.device.status == "empty") {
      return;
    }
    statusLiveMap = widget.device.rawdata['status_history'] ?? [];
    if (statusLiveMap.length >= 10) {
      statusLiveMap.removeAt(0);
    }
    for (int i = 0; i < statusLiveMap.length; i++) {
      statusLiveMap[i]['index'] = i;
    }
    //resverse list
    statusLiveMap = statusLiveMap.reversed.toList();
    if (mounted) {
      setState(() {});
    }
  }

  // void getHistory() {
  //   HttpReq().getStatHistory(widget.device.token, nowDateRange.start.millisecondsSinceEpoch.toString(), nowDateRange.end.millisecondsSinceEpoch.toString()).then((value) {
  //     if (value == "SERVER ERROR") {
  //       setState(() {
  //         serverError = true;
  //       });
  //     } else {
  //       setState(() {
  //         serverError = false;
  //         statusHistoryMap = value;
  //       });
  //     }
  //   });
  // }

  void testadd() {
    Map<String, dynamic> test = {"voltage": Random().nextInt(9).toDouble() + 1};
    statusLiveMap.add(test);
    if (statusLiveMap.length >= 10) {
      statusLiveMap.removeAt(0);
    }

    //update index
    for (int i = 0; i < statusLiveMap.length; i++) {
      statusLiveMap[i]['index'] = i;
    }
  }

  final _controller = PageController(
    initialPage: 0,
  );
  final _controllerhis = PageController(
    initialPage: 0,
  );

  Future<void> inputnewpass() async {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (BuildContext context, setState) {
              return AlertDialog(
                title: const Text('密碼保護'),
                contentPadding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0.0),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            autofocus: true,
                            obscureText: !showpassword,
                            onChanged: (text) {
                              setState(() {});
                            },
                            controller: passwordverifyinput,
                            maxLength: 6,
                            //only eng and number and space and _ and ()
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                            ],
                            keyboardType: TextInputType.number,

                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              labelText: '驗證新密碼',
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    showpassword = !showpassword;
                                  });
                                },
                                icon: Icon(showpassword ? Icons.visibility : Icons.visibility_off),
                              ),
                            ),
                          ),
                        ),
                        //clear button
                      ],
                    )
                  ],
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('確定'),
                  ),
                ],
              );
            },
          );
        });
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
    _controllerhis.dispose();
    timer.cancel();
    timer_setting.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: Container(
          decoration: BoxDecoration(
              image: DecorationImage(
            //image 靠右上
            //random from assets/images/background/

            image: AssetImage(imgrandom),
            fit: BoxFit.cover,
          )),
          child: Column(
            children: [
              Container(
                  color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.1),
                  height: MediaQuery.of(context).padding.top + 50,
                  child: Column(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).padding.top,
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () {
                              //jump to register new
                              Navigator.pop(context);
                            },
                          ),
                          Expanded(
                            child: Container(
                              alignment: Alignment.center,
                              child: Text(
                                serverError ? widget.device.setting['name'] + " (Server Error)" : widget.device.setting['name'],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: !serverError ? const Color.fromARGB(255, 0, 0, 0) : Colors.red,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.settings),
                            onPressed: () {
                              //設定選單
                              showDialog(
                                context: context,
                                builder: (BuildContext dialogContext) {
                                  return AlertDialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      title: const Text('設定選單'),
                                      content: SizedBox(
                                          height: MediaQuery.of(context).size.height * 0.4,
                                          width: MediaQuery.of(context).size.width * 0.5,
                                          child: SingleChildScrollView(
                                            child: Column(children: [
                                              GestureDetector(
                                                onTap: () {
                                                  // Handle changing device name logic
                                                  nameinput.text = widget.device.setting['name'];
                                                  showDialog(
                                                      context: context,
                                                      builder: (BuildContext context) {
                                                        return StatefulBuilder(
                                                          builder: (BuildContext context, setState) {
                                                            return AlertDialog(
                                                              //50% of screen
                                                              contentPadding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0.0),

                                                              title: const Text('設定名稱'),
                                                              content: Column(
                                                                mainAxisSize: MainAxisSize.min,
                                                                children: [
                                                                  Row(
                                                                    children: [
                                                                      Expanded(
                                                                        child: TextField(
                                                                          autofocus: true,
                                                                          onChanged: (text) {
                                                                            setState(() {});
                                                                          },
                                                                          controller: nameinput,
                                                                          maxLength: 12,
                                                                          //only eng and number and space and _ and () and -
                                                                          inputFormatters: [
                                                                            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9 _()-]')),
                                                                          ],

                                                                          decoration: InputDecoration(
                                                                            border: const OutlineInputBorder(),
                                                                            labelText: '名稱',
                                                                            suffixIcon: IconButton(
                                                                              onPressed: () {
                                                                                nameinput.clear();
                                                                              },
                                                                              icon: const Icon(Icons.clear),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      //clear button
                                                                    ],
                                                                  )
                                                                ],
                                                              ),
                                                              actions: <Widget>[
                                                                TextButton(
                                                                  onPressed: () {
                                                                    if (nameinput.text != "") {
                                                                      HttpReq().setting(widget.device.token, {"name": nameinput.text}).then((value) => {
                                                                            if (value)
                                                                              {
                                                                                SharedPreferences.getInstance().then((SharedPreferences sharedPreference) {
                                                                                  List<String> listString = sharedPreference.getStringList('devices') ?? [];

                                                                                  for (int i = 0; i < listString.length; i++) {
                                                                                    Device tempdevice = Device.fromJson(jsonDecode(listString[i]));
                                                                                    if (tempdevice.token == widget.device.token) {
                                                                                      tempdevice.setting['name'] = nameinput.text;
                                                                                      listString[i] = jsonEncode(tempdevice.toJson());
                                                                                      break;
                                                                                    }
                                                                                  }
                                                                                  sharedPreference.setStringList('devices', listString);
                                                                                  widget.device.setting['name'] = nameinput.text;
                                                                                }),
                                                                                SmartDialog.showToast("設定成功"),
                                                                                Navigator.pop(dialogContext), // Close the dialog
                                                                              }
                                                                            else
                                                                              {
                                                                                SmartDialog.showToast("設定失敗"),
                                                                                Navigator.pop(dialogContext) // Close the dialog
                                                                              }
                                                                          });
                                                                    } else {
                                                                      SmartDialog.showToast("名稱不可為空");
                                                                    }
                                                                    Navigator.of(context).pop();
                                                                  },
                                                                  child: const Text('確定'),
                                                                ),
                                                              ],
                                                            );
                                                          },
                                                        );
                                                      });
                                                },
                                                child: const Padding(
                                                  padding: EdgeInsets.symmetric(vertical: 8.0),
                                                  child: ListTile(
                                                    leading: Icon(Icons.edit),
                                                    title: Text('設定名稱'),
                                                  ), // Set Name
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () {
                                                  SharedPreferences.getInstance().then((SharedPreferences sharedPreference) {
                                                    List<String> listString = sharedPreference.getStringList('devices') ?? [];

                                                    for (int i = 0; i < listString.length; i++) {
                                                      Device tempdevice = Device.fromJson(jsonDecode(listString[i]));
                                                      if (tempdevice.token == widget.device.token) {
                                                        listString.removeAt(i);
                                                        break;
                                                      }
                                                    }
                                                    sharedPreference.setStringList('devices', listString);
                                                    Navigator.of(context).popUntil((route) => route.isFirst);
                                                    Navigator.of(context).maybePop();
                                                    Navigator.of(context).maybePop();
                                                    Navigator.of(context).maybePop();

                                                    Navigator.pushReplacement(
                                                        context,
                                                        PageRouteBuilder(
                                                            transitionDuration: const Duration(milliseconds: 200),
                                                            pageBuilder: (context, animation, secondaryAnimation) {
                                                              return FadeTransition(
                                                                opacity: animation,
                                                                child: const HomePage(),
                                                              );
                                                            }));
                                                  });

                                                  Navigator.pop(dialogContext); // Close the dialog
                                                },
                                                child: const Padding(
                                                  padding: EdgeInsets.symmetric(vertical: 8.0),
                                                  child: ListTile(
                                                    leading: Icon(Icons.delete),
                                                    title: Text('刪除裝置'),
                                                  ), // Delete Device
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () {
                                                  // Handle changing device name logic
                                                  Navigator.pop(dialogContext); // Close the dialog
                                                  lineLogin().connectToLine(widget.device).then((value) => {
                                                        if (value)
                                                          {
                                                            SmartDialog.showToast("連結成功"),
                                                          }
                                                        else
                                                          {
                                                            SmartDialog.showToast("連結失敗"),
                                                          }
                                                      });
                                                },
                                                child: const Padding(
                                                  padding: EdgeInsets.symmetric(vertical: 8.0),
                                                  child: ListTile(
                                                    leading: FaIcon(FontAwesomeIcons.line),
                                                    title: Text('連結至Line'),
                                                  ),
                                                ),
                                              ),
                                              GestureDetector(
                                                child: const Padding(
                                                  padding: EdgeInsets.symmetric(vertical: 8.0),
                                                  child: ListTile(
                                                    leading: Icon(Icons.notification_important),
                                                    title: Text('設定安全範圍'),
                                                  ),
                                                ),
                                                onTap: () => {
                                                  showDialog(
                                                      context: context,
                                                      builder: (BuildContext context) {
                                                        return StatefulBuilder(
                                                          builder: (BuildContext context, setState) {
                                                            return AlertDialog(
                                                              //50% of screen
                                                              contentPadding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0.0),

                                                              title: const Text('安全範圍設定'),
                                                              content: Column(
                                                                mainAxisSize: MainAxisSize.min,
                                                                children: [
                                                                  SizedBox(
                                                                    width: MediaQuery.of(context).size.width * 0.7,
                                                                  ),
                                                                  Text('溫度 $safeMinTemp°C ~ $safeMaxTemp°C'),
                                                                  RangeSlider(
                                                                      activeColor: (safeMaxTemp > 60) ? Colors.red : Colors.blue,
                                                                      inactiveColor: (safeMaxTemp > 60) ? Colors.red.withOpacity(0.2) : Colors.blue.withOpacity(0.2),
                                                                      values: RangeValues(safeMinTemp, safeMaxTemp),
                                                                      min: 20,
                                                                      max: 80,
                                                                      onChanged: (values) => setState(() {
                                                                            //使用0.5為單位
                                                                            safeMinTemp = values.start - values.start % 0.5;
                                                                            safeMaxTemp = values.end - values.end % 0.5;
                                                                          })),
                                                                  Text('電壓 $safeMinVoltage V ~ $safeMaxVoltage V'),
                                                                  RangeSlider(
                                                                      values: RangeValues(safeMinVoltage, safeMaxVoltage),
                                                                      min: 80,
                                                                      max: 250,
                                                                      onChanged: (values) => setState(() {
                                                                            //使用0.5為單位
                                                                            safeMinVoltage = values.start - values.start % 0.5;
                                                                            safeMaxVoltage = values.end - values.end % 0.5;
                                                                          })),
                                                                  Text('瓦數 $safeMaxWatt W'),
                                                                  Slider(
                                                                      value: safeMaxWatt,
                                                                      activeColor: (safeMaxWatt > 1000) ? Colors.red : Colors.blue,
                                                                      inactiveColor: (safeMaxWatt > 1000) ? Colors.red.withOpacity(0.2) : Colors.blue.withOpacity(0.2),
                                                                      min: 0,
                                                                      max: 1500,
                                                                      onChanged: (value) => setState(() {
                                                                            //使用0.5為單位
                                                                            safeMaxWatt = value - value % 0.5;
                                                                          })),
                                                                ],
                                                              ),
                                                              actions: <Widget>[
                                                                Row(children: [
                                                                  TextButton(
                                                                    onPressed: () {
                                                                      setState(() {
                                                                        safeMinTemp = 20;
                                                                        safeMaxTemp = 60;
                                                                        safeMinVoltage = 80;
                                                                        safeMaxVoltage = 250;
                                                                        safeMaxWatt = 1000;
                                                                      });
                                                                    },
                                                                    child: const Text('恢復預設'),
                                                                  ),
                                                                  const Expanded(child: SizedBox()),
                                                                  TextButton(
                                                                    onPressed: () {
                                                                      Navigator.pop(dialogContext);
                                                                    },
                                                                    child: const Text('取消'),
                                                                  ),
                                                                  TextButton(
                                                                    onPressed: () {
                                                                      HttpReq().setting(widget.device.token, {
                                                                        "safeMinTemp": safeMinTemp.toString(),
                                                                        "safeMaxTemp": safeMaxTemp.toString(),
                                                                        "safeMinVoltage": safeMinVoltage.toString(),
                                                                        "safeMaxVoltage": safeMaxVoltage.toString(),
                                                                        "safeMaxWatt": safeMaxWatt.toString(),
                                                                      }).then((value) => {
                                                                            if (value)
                                                                              {
                                                                                SharedPreferences.getInstance().then((SharedPreferences sharedPreference) {
                                                                                  List<String> listString = sharedPreference.getStringList('devices') ?? [];

                                                                                  for (int i = 0; i < listString.length; i++) {
                                                                                    Device tempdevice = Device.fromJson(jsonDecode(listString[i]));
                                                                                    if (tempdevice.token == widget.device.token) {
                                                                                      tempdevice.setting['safeMinTemp'] = safeMinTemp.toString();
                                                                                      tempdevice.setting['safeMaxTemp'] = safeMaxTemp.toString();
                                                                                      tempdevice.setting['safeMinVoltage'] = safeMinVoltage.toString();
                                                                                      tempdevice.setting['safeMaxVoltage'] = safeMaxVoltage.toString();
                                                                                      tempdevice.setting['safeMaxWatt'] = safeMaxWatt.toString();
                                                                                      listString[i] = jsonEncode(tempdevice.toJson());
                                                                                      break;
                                                                                    }
                                                                                  }
                                                                                  sharedPreference.setStringList('devices', listString);
                                                                                  widget.device.setting['safeMinTemp'] = safeMinTemp.toString();
                                                                                  widget.device.setting['safeMaxTemp'] = safeMaxTemp.toString();
                                                                                  widget.device.setting['safeMinVoltage'] = safeMinVoltage.toString();
                                                                                  widget.device.setting['safeMaxVoltage'] = safeMaxVoltage.toString();
                                                                                  widget.device.setting['safeMaxWatt'] = safeMaxWatt.toString();
                                                                                }),
                                                                                SmartDialog.showToast("設定成功"),
                                                                                Navigator.pop(dialogContext), // Close the dialog
                                                                              }
                                                                            else
                                                                              {
                                                                                SmartDialog.showToast("設定失敗"),
                                                                                Navigator.pop(dialogContext) // Close the dialog
                                                                              }
                                                                          });
                                                                    },
                                                                    child: const Text('確定'),
                                                                  ),
                                                                ])
                                                              ],
                                                            );
                                                          },
                                                        );
                                                      }),
                                                },
                                              ),
                                              GestureDetector(
                                                onTap: () {
                                                  passwordoldinput.clear();
                                                  passwordnewinput.clear();
                                                  passwordverifyinput.clear();
                                                  showDialog(
                                                      context: context,
                                                      builder: (BuildContext context) {
                                                        return StatefulBuilder(
                                                          builder: (BuildContext context, setState) {
                                                            return AlertDialog(
                                                              title: const Text('密碼保護'),
                                                              contentPadding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0.0),
                                                              content: Column(
                                                                mainAxisSize: MainAxisSize.min,
                                                                children: [
                                                                  Row(
                                                                    children: [
                                                                      Expanded(
                                                                        child: TextField(
                                                                          autofocus: true,
                                                                          obscureText: !showpassword,
                                                                          onChanged: (text) {
                                                                            setState(() {});
                                                                          },
                                                                          controller: passwordoldinput,
                                                                          maxLength: 6,
                                                                          //only eng and number and space and _ and ()
                                                                          inputFormatters: [
                                                                            FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                                                                          ],
                                                                          keyboardType: TextInputType.number,

                                                                          decoration: InputDecoration(
                                                                            border: const OutlineInputBorder(),
                                                                            labelText: '輸入舊密碼',
                                                                            suffixIcon: IconButton(
                                                                              onPressed: () {
                                                                                setState(() {
                                                                                  showpassword = !showpassword;
                                                                                });
                                                                              },
                                                                              icon: Icon(showpassword ? Icons.visibility : Icons.visibility_off),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      //clear button
                                                                    ],
                                                                  )
                                                                ],
                                                              ),
                                                              actions: <Widget>[
                                                                TextButton(
                                                                  onPressed: () {
                                                                    Navigator.of(context).pop();
                                                                    showDialog(
                                                                        context: context,
                                                                        builder: (BuildContext context) {
                                                                          return StatefulBuilder(
                                                                            builder: (BuildContext context, setState) {
                                                                              return AlertDialog(
                                                                                title: const Text('密碼保護'),
                                                                                contentPadding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0.0),
                                                                                content: Column(
                                                                                  mainAxisSize: MainAxisSize.min,
                                                                                  children: [
                                                                                    Row(
                                                                                      children: [
                                                                                        Expanded(
                                                                                          child: TextField(
                                                                                            autofocus: true,
                                                                                            obscureText: !showpassword,
                                                                                            onChanged: (text) {
                                                                                              setState(() {});
                                                                                            },
                                                                                            controller: passwordnewinput,
                                                                                            maxLength: 6,
                                                                                            //only eng and number and space and _ and ()
                                                                                            inputFormatters: [
                                                                                              FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                                                                                            ],
                                                                                            keyboardType: TextInputType.number,

                                                                                            decoration: InputDecoration(
                                                                                              border: const OutlineInputBorder(),
                                                                                              labelText: '新密碼',
                                                                                              suffixIcon: IconButton(
                                                                                                onPressed: () {
                                                                                                  setState(() {
                                                                                                    showpassword = !showpassword;
                                                                                                  });
                                                                                                },
                                                                                                icon: Icon(showpassword ? Icons.visibility : Icons.visibility_off),
                                                                                              ),
                                                                                            ),
                                                                                          ),
                                                                                        ),
                                                                                        //clear button
                                                                                      ],
                                                                                    )
                                                                                  ],
                                                                                ),
                                                                                actions: <Widget>[
                                                                                  TextButton(
                                                                                    onPressed: () {
                                                                                      Navigator.of(context).pop();
                                                                                    },
                                                                                    child: const Text('確定'),
                                                                                  ),
                                                                                ],
                                                                              );
                                                                            },
                                                                          );
                                                                        });
                                                                  },
                                                                  child: const Text('確定'),
                                                                ),
                                                              ],
                                                            );
                                                          },
                                                        );
                                                      });
                                                },
                                                child: const Padding(
                                                  padding: EdgeInsets.symmetric(vertical: 8.0),
                                                  child: ListTile(
                                                    leading: Icon(Icons.lock),
                                                    title: Text('密碼保護'),
                                                  ), // Change Image
                                                ),
                                              ),
                                            ]),
                                          )),
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text('關閉'),
                                        ),
                                      ]);
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  )),
              _selectedIndex == 0
                  ? Expanded(
                      child: Column(
                        children: [
                          MediaQuery.of(context).size.height > 1000 ? widget.deviceCard : const SizedBox(height: 0),
                          Expanded(
                              child: MediaQuery.removePadding(
                            //解决listview顶部有个空白的问题。
                            removeTop: true,
                            context: context,
                            child: ListView(
                              children: [
                                MediaQuery.of(context).size.height < 1000 ? widget.deviceCard : const SizedBox(height: 0),
                                Container(
                                    margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                                    padding: MediaQuery.of(context).size.width > 600 ? const EdgeInsets.fromLTRB(20, 10, 20, 10) : const EdgeInsets.fromLTRB(5, 5, 5, 5),
                                    decoration: BoxDecoration(
                                      color: Platform.isIOS ? Colors.white.withOpacity(0.8) : Colors.white.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black12,
                                          offset: Offset(0, 2),
                                          blurRadius: 4.0,
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                                margin: const EdgeInsets.only(top: 5, bottom: 5, left: 5, right: 5),
                                                padding: const EdgeInsets.only(top: 5, bottom: 5, left: 10, right: 10),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(10),
                                                  boxShadow: const [
                                                    BoxShadow(
                                                      color: Color.fromARGB(255, 0, 0, 0),
                                                      offset: Offset(0, 0),
                                                      blurRadius: 1.0,
                                                    ),
                                                  ],
                                                ),
                                                child: Row(children: [
                                                  TextButton(
                                                    style: MediaQuery.of(context).size.width < 600
                                                        ? TextButton.styleFrom(
                                                            padding: EdgeInsets.zero,
                                                            minimumSize: Size.zero,
                                                          )
                                                        : TextButton.styleFrom(),
                                                    child: Text(
                                                      "瓦數",
                                                      style: TextStyle(color: (nowfhartpage == 0 ? Colors.black : Colors.grey), fontSize: (nowfhartpage == 0 ? 25 : 10)),
                                                    ),
                                                    onPressed: () {
                                                      setState(() {
                                                        showlivechart = true;
                                                      });
                                                      _controller.animateToPage(0, duration: const Duration(milliseconds: 500), curve: Curves.ease);
                                                    },
                                                  ),
                                                  TextButton(
                                                    style: MediaQuery.of(context).size.width < 600
                                                        ? TextButton.styleFrom(
                                                            padding: EdgeInsets.zero,
                                                            minimumSize: Size.zero,
                                                          )
                                                        : TextButton.styleFrom(),
                                                    child: Text(
                                                      "電壓",
                                                      style: TextStyle(color: (nowfhartpage == 1 ? Colors.black : Colors.grey), fontSize: (nowfhartpage == 1 ? 25 : 10)),
                                                    ),
                                                    onPressed: () {
                                                      setState(() {
                                                        showlivechart = true;
                                                      });
                                                      _controller.animateToPage(1, duration: const Duration(milliseconds: 500), curve: Curves.ease);
                                                    },
                                                  ),
                                                  TextButton(
                                                    style: MediaQuery.of(context).size.width < 600
                                                        ? TextButton.styleFrom(
                                                            padding: EdgeInsets.zero,
                                                            minimumSize: Size.zero,
                                                          )
                                                        : TextButton.styleFrom(),
                                                    child: Text(
                                                      "溫度",
                                                      style: TextStyle(color: (nowfhartpage == 2 ? Colors.black : Colors.grey), fontSize: (nowfhartpage == 2 ? 25 : 10)),
                                                    ),
                                                    onPressed: () {
                                                      setState(() {
                                                        showlivechart = true;
                                                      });
                                                      _controller.animateToPage(2, duration: const Duration(milliseconds: 500), curve: Curves.ease);
                                                    },
                                                  ),
                                                ])),
                                            const Expanded(child: SizedBox()),
                                            Row(
                                              children: [
                                                MediaQuery.of(context).size.width > 500
                                                    ? const Text(
                                                        "顯示實時圖表",
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                        ),
                                                      )
                                                    : const SizedBox(),
                                                const SizedBox(
                                                  width: 5,
                                                ),
                                                SwitcherXlive(
                                                  unActiveColor: Colors.grey,
                                                  activeColor: Colors.blue,
                                                  value: showlivechart,
                                                  onChanged: ((value) => {
                                                        setState(() {
                                                          showlivechart = value;
                                                        })
                                                      }),
                                                ),
                                              ],
                                            )
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        AnimatedSwitcher(
                                            duration: const Duration(milliseconds: 500),
                                            child: showlivechart
                                                ? AspectRatio(
                                                    aspectRatio: 1.5,
                                                    child: PageView(
                                                      onPageChanged: (int page) => {
                                                        setState(() {
                                                          nowfhartpage = page;
                                                        })
                                                      },
                                                      controller: _controller,
                                                      children: [
                                                        widget.device.status == "OFFLINE"
                                                            ? Container(
                                                                decoration: BoxDecoration(
                                                                  color: const Color.fromARGB(255, 255, 255, 255),
                                                                  borderRadius: BorderRadius.circular(10),
                                                                  boxShadow: const [
                                                                    BoxShadow(
                                                                      color: Colors.black12,
                                                                      offset: Offset(0, 2),
                                                                      blurRadius: 4.0,
                                                                    ),
                                                                  ],
                                                                ),
                                                                child: const Center(
                                                                    child: Text(
                                                                  "裝置離線",
                                                                  style: TextStyle(fontSize: 30),
                                                                )))
                                                            : Column(
                                                                children: [
                                                                  Expanded(
                                                                      child: SfCartesianChart(
                                                                    primaryXAxis: CategoryAxis(),
                                                                    series: <ChartSeries>[
                                                                      SplineSeries<dynamic, dynamic>(
                                                                        dataSource: statusLiveMap,
                                                                        xValueMapper: (data, _) => data['index'],
                                                                        yValueMapper: (data, _) => data['current1'] * data['voltage'] * 0.001,
                                                                        //color
                                                                        pointColorMapper: (data, _) => Colors.blue,
                                                                      ),
                                                                      SplineSeries<dynamic, dynamic>(
                                                                        dataSource: statusLiveMap,
                                                                        xValueMapper: (data, _) => data['index'],
                                                                        yValueMapper: (data, _) => data['current2'] * data['voltage'] * 0.001,
                                                                        pointColorMapper: (data, _) => Colors.green,
                                                                      ),
                                                                    ],
                                                                    //線對齊
                                                                    enableAxisAnimation: true,
                                                                    primaryYAxis: NumericAxis(
                                                                      //w顯示在數字後面
                                                                      numberFormat: NumberFormat.currency(locale: 'zh_TW', symbol: '', decimalDigits: 0, customPattern: "####W"),
                                                                    ),
                                                                  )),
                                                                  Row(
                                                                    //上下左右居中
                                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                                    children: [
                                                                      const Text("插座1"),
                                                                      const SizedBox(
                                                                        width: 5,
                                                                      ),
                                                                      Container(
                                                                        decoration: BoxDecoration(
                                                                          color: Colors.blue,
                                                                          borderRadius: BorderRadius.circular(10),
                                                                        ),
                                                                        margin: EdgeInsets.only(top: MediaQuery.of(context).size.width * 0.01),
                                                                        width: MediaQuery.of(context).size.width * 0.05,
                                                                        height: MediaQuery.of(context).size.width * 0.01,
                                                                      ),
                                                                      const SizedBox(
                                                                        width: 5,
                                                                      ),
                                                                      const Text("插座2"),
                                                                      const SizedBox(
                                                                        width: 5,
                                                                      ),
                                                                      Container(
                                                                        decoration: BoxDecoration(
                                                                          color: Colors.green,
                                                                          borderRadius: BorderRadius.circular(10),
                                                                        ),
                                                                        margin: EdgeInsets.only(top: MediaQuery.of(context).size.width * 0.01),
                                                                        width: MediaQuery.of(context).size.width * 0.05,
                                                                        height: MediaQuery.of(context).size.width * 0.01,
                                                                      ),
                                                                    ],
                                                                  )
                                                                ],
                                                              ),
                                                        widget.device.status == "OFFLINE"
                                                            ? Container(
                                                                decoration: BoxDecoration(
                                                                  color: const Color.fromARGB(255, 255, 255, 255),
                                                                  borderRadius: BorderRadius.circular(10),
                                                                  boxShadow: const [
                                                                    BoxShadow(
                                                                      color: Colors.black12,
                                                                      offset: Offset(0, 2),
                                                                      blurRadius: 4.0,
                                                                    ),
                                                                  ],
                                                                ),
                                                                child: const Center(
                                                                    child: Text(
                                                                  "裝置離線",
                                                                  style: TextStyle(fontSize: 30),
                                                                )))
                                                            : SfCartesianChart(
                                                                primaryXAxis: CategoryAxis(),
                                                                series: <ChartSeries>[
                                                                  SplineSeries<dynamic, dynamic>(
                                                                    dataSource: statusLiveMap,
                                                                    xValueMapper: (data, _) => data['index'],
                                                                    yValueMapper: (data, _) => data['voltage'],
                                                                  ),
                                                                ],
                                                                //線對齊
                                                                enableAxisAnimation: true,
                                                                primaryYAxis: NumericAxis(
                                                                  //w顯示在數字後面
                                                                  numberFormat: NumberFormat.currency(locale: 'zh_TW', symbol: '', decimalDigits: 1, customPattern: "####V"),
                                                                ),
                                                              ),
                                                        widget.device.status == "OFFLINE"
                                                            ? Container(
                                                                decoration: BoxDecoration(
                                                                  color: const Color.fromARGB(255, 255, 255, 255),
                                                                  borderRadius: BorderRadius.circular(10),
                                                                  boxShadow: const [
                                                                    BoxShadow(
                                                                      color: Colors.black12,
                                                                      offset: Offset(0, 2),
                                                                      blurRadius: 4.0,
                                                                    ),
                                                                  ],
                                                                ),
                                                                child: const Center(
                                                                    child: Text(
                                                                  "裝置離線",
                                                                  style: TextStyle(fontSize: 30),
                                                                )))
                                                            : SfCartesianChart(
                                                                primaryXAxis: CategoryAxis(),
                                                                series: <ChartSeries>[
                                                                  SplineSeries<dynamic, dynamic>(
                                                                    dataSource: statusLiveMap,
                                                                    xValueMapper: (data, _) => data['index'],
                                                                    yValueMapper: (data, _) => data['temp'],
                                                                  ),
                                                                ],
                                                                //線對齊
                                                                enableAxisAnimation: true,
                                                                primaryYAxis: NumericAxis(
                                                                  //w顯示在數字後面
                                                                  numberFormat: NumberFormat.currency(locale: 'zh_TW', symbol: '', decimalDigits: 1, customPattern: "####.#°C"),
                                                                ),
                                                              ),
                                                      ],
                                                    ))
                                                : const SizedBox()),
                                      ],
                                    )),
                                Container(
                                    margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                                    padding: MediaQuery.of(context).size.width > 600 ? const EdgeInsets.fromLTRB(20, 10, 20, 10) : const EdgeInsets.fromLTRB(5, 5, 5, 5),
                                    decoration: BoxDecoration(
                                      color: Platform.isIOS ? Colors.white.withOpacity(0.8) : Colors.white.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black12,
                                          offset: Offset(0, 2),
                                          blurRadius: 4.0,
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                                margin: const EdgeInsets.only(top: 5, bottom: 5, left: 5, right: 5),
                                                padding: const EdgeInsets.only(top: 5, bottom: 5, left: 10, right: 10),
                                                decoration: BoxDecoration(
                                                  color: const Color.fromARGB(255, 255, 255, 255),
                                                  borderRadius: BorderRadius.circular(10),
                                                  boxShadow: const [
                                                    BoxShadow(
                                                      color: Color.fromARGB(255, 0, 0, 0),
                                                      offset: Offset(0, 0),
                                                      blurRadius: 1.0,
                                                    ),
                                                  ],
                                                ),
                                                child: Row(children: [
                                                  TextButton(
                                                    style: MediaQuery.of(context).size.width < 600
                                                        ? TextButton.styleFrom(
                                                            padding: EdgeInsets.zero,
                                                            minimumSize: Size.zero,
                                                          )
                                                        : TextButton.styleFrom(),
                                                    child: Text(
                                                      "瓦數",
                                                      style: TextStyle(color: (nowhistorypage == 0 ? Colors.black : Colors.grey), fontSize: (nowhistorypage == 0 ? 25 : 10)),
                                                    ),
                                                    onPressed: () {
                                                      setState(() {
                                                        showhistorychart = true;
                                                        HttpReq().getHistory(widget.device.token, nowDateRange).then((hisr) => {
                                                              if (hisr != null)
                                                                {
                                                                  setState(() {
                                                                    statusHistoryMap = hisr;
                                                                  })
                                                                }
                                                            });
                                                      });
                                                      _controllerhis.animateToPage(0, duration: const Duration(milliseconds: 500), curve: Curves.ease);
                                                    },
                                                  ),
                                                  TextButton(
                                                    style: MediaQuery.of(context).size.width < 600
                                                        ? TextButton.styleFrom(
                                                            padding: EdgeInsets.zero,
                                                            minimumSize: Size.zero,
                                                          )
                                                        : TextButton.styleFrom(),
                                                    child: Text(
                                                      "電壓",
                                                      style: TextStyle(color: (nowhistorypage == 1 ? Colors.black : Colors.grey), fontSize: (nowhistorypage == 1 ? 25 : 10)),
                                                    ),
                                                    onPressed: () {
                                                      setState(() {
                                                        showhistorychart = true;
                                                        HttpReq().getHistory(widget.device.token, nowDateRange).then((hisr) => {
                                                              if (hisr != null)
                                                                {
                                                                  setState(() {
                                                                    statusHistoryMap = hisr;
                                                                  })
                                                                }
                                                            });
                                                      });
                                                      _controllerhis.animateToPage(1, duration: const Duration(milliseconds: 500), curve: Curves.ease);
                                                    },
                                                  ),
                                                  TextButton(
                                                    style: MediaQuery.of(context).size.width < 600
                                                        ? TextButton.styleFrom(
                                                            padding: EdgeInsets.zero,
                                                            minimumSize: Size.zero,
                                                          )
                                                        : TextButton.styleFrom(),
                                                    child: Text(
                                                      "溫度",
                                                      style: TextStyle(color: (nowhistorypage == 2 ? Colors.black : Colors.grey), fontSize: (nowhistorypage == 2 ? 25 : 10)),
                                                    ),
                                                    onPressed: () {
                                                      setState(() {
                                                        showhistorychart = true;
                                                        HttpReq().getHistory(widget.device.token, nowDateRange).then((hisr) => {
                                                              if (hisr != null)
                                                                {
                                                                  setState(() {
                                                                    statusHistoryMap = hisr;
                                                                  })
                                                                }
                                                            });
                                                      });
                                                      _controllerhis.animateToPage(2, duration: const Duration(milliseconds: 500), curve: Curves.ease);
                                                    },
                                                  ),
                                                ])),
                                            const Expanded(child: SizedBox()),
                                            const Expanded(child: SizedBox()),
                                            Row(
                                              children: [
                                                MediaQuery.of(context).size.width > 500
                                                    ? const Text(
                                                        "顯示歷史圖表",
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                        ),
                                                      )
                                                    : const SizedBox(),
                                                const SizedBox(
                                                  width: 5,
                                                ),
                                                SwitcherXlive(
                                                    unActiveColor: Colors.grey,
                                                    activeColor: Colors.blue,
                                                    value: showhistorychart,
                                                    onChanged: ((value) => {
                                                          setState(() {
                                                            showhistorychart = value;
                                                            if (value) {
                                                              //convert to DateTimeRange
                                                              HttpReq().getHistory(widget.device.token, nowDateRange).then((hisr) => {
                                                                    if (hisr != null)
                                                                      {
                                                                        setState(() {
                                                                          statusHistoryMap = hisr;
                                                                        })
                                                                      }
                                                                  });
                                                            }
                                                          })
                                                        })),
                                              ],
                                            )
                                          ],
                                        ),
                                        Container(
                                          margin: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                                          padding: MediaQuery.of(context).size.width > 600 ? const EdgeInsets.fromLTRB(5, 5, 5, 5) : const EdgeInsets.fromLTRB(0, 0, 0, 0),
                                          decoration: BoxDecoration(
                                            color: const Color.fromARGB(255, 255, 255, 255),
                                            borderRadius: BorderRadius.circular(10),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Colors.black12,
                                                offset: Offset(0, 2),
                                                blurRadius: 4.0,
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              //two box that show start and end date with shadow
                                              Row(
                                                children: [
                                                  MediaQuery.of(context).size.width > 500
                                                      ? IconButton(
                                                          //往前一個禮拜
                                                          onPressed: () {
                                                            setState(() {
                                                              nowDateRange =
                                                                  DateTimeRange(start: nowDateRange.start.subtract(const Duration(days: 7)), end: nowDateRange.end.subtract(const Duration(days: 7)));
                                                            });
                                                            SmartDialog.showToast('往前一個禮拜', displayTime: const Duration(milliseconds: 500));
                                                          },
                                                          icon: const Icon(Icons.first_page))
                                                      : const SizedBox(),
                                                  MediaQuery.of(context).size.width > 500
                                                      ? IconButton(
                                                          onPressed: () {
                                                            //往前一天
                                                            setState(() {
                                                              nowDateRange =
                                                                  DateTimeRange(start: nowDateRange.start.subtract(const Duration(days: 1)), end: nowDateRange.end.subtract(const Duration(days: 1)));
                                                            });
                                                            SmartDialog.showToast('往前一天', displayTime: const Duration(milliseconds: 500));
                                                          },
                                                          icon: const Icon(Icons.chevron_left))
                                                      : const SizedBox(),
                                                  const SizedBox(width: 10),
                                                  TextButton(
                                                      onPressed: () {
                                                        showDialog<Widget>(
                                                            context: context,
                                                            builder: (BuildContext context) {
                                                              return Dialog(
                                                                child: Container(
                                                                  padding: const EdgeInsets.all(10),
                                                                  height: MediaQuery.of(context).size.height * 0.8 <= 500 ? MediaQuery.of(context).size.height * 0.8 : 500,
                                                                  width: MediaQuery.of(context).size.width * 0.8 <= 500 ? MediaQuery.of(context).size.width * 0.8 : 500,
                                                                  child: SfDateRangePicker(
                                                                    initialSelectedRange: PickerDateRange(nowDateRange.start, nowDateRange.end),
                                                                    maxDate: DateTime.now(),
                                                                    selectionMode: DateRangePickerSelectionMode.range,
                                                                    showActionButtons: true,
                                                                    onSubmit: (value) {
                                                                      Navigator.pop(context);
                                                                      setState(() {
                                                                        PickerDateRange range = value as PickerDateRange;
                                                                        //convert to DateTimeRange
                                                                        nowDateRange = DateTimeRange(start: range.startDate ?? DateTime.now(), end: range.endDate ?? DateTime.now());
                                                                        HttpReq().getHistory(widget.device.token, nowDateRange).then((value) => {
                                                                              if (value != null)
                                                                                {
                                                                                  setState(() {
                                                                                    statusHistoryMap = value;
                                                                                  })
                                                                                }
                                                                            });
                                                                      });
                                                                    },
                                                                    onCancel: () {
                                                                      Navigator.pop(context);
                                                                    },
                                                                  ),
                                                                ),
                                                              );
                                                            });
                                                      },
                                                      child: Row(children: [
                                                        Container(
                                                          constraints: const BoxConstraints(minWidth: 100),
                                                          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                                                          decoration: BoxDecoration(
                                                            color: const Color.fromARGB(255, 255, 255, 255),
                                                            borderRadius: BorderRadius.circular(10),
                                                            boxShadow: const [
                                                              BoxShadow(
                                                                color: Color.fromARGB(255, 0, 136, 255),
                                                                offset: Offset(0, 0),
                                                                blurRadius: 1,
                                                              ),
                                                            ],
                                                          ),
                                                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                                            Text(
                                                              nowDateRange.start == nowDateRange.end ? "Date" : "Start Date",
                                                              style: const TextStyle(color: Color.fromARGB(255, 145, 145, 145)),
                                                            ),
                                                            Text(
                                                              "${nowDateRange.start.year}/${nowDateRange.start.month}/${nowDateRange.start.day}",
                                                              style: const TextStyle(
                                                                color: Colors.black,
                                                                fontSize: 16,
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            ),
                                                          ]),
                                                        ),
                                                        nowDateRange.start == nowDateRange.end
                                                            ? const SizedBox()
                                                            : (MediaQuery.of(context).size.width > 600 ? const SizedBox(width: 10) : const SizedBox()),
                                                        nowDateRange.start == nowDateRange.end
                                                            ? const SizedBox()
                                                            : (MediaQuery.of(context).size.width > 600 ? const Icon(Icons.horizontal_rule) : const SizedBox()),
                                                        nowDateRange.start == nowDateRange.end
                                                            ? const SizedBox()
                                                            : (MediaQuery.of(context).size.width > 600
                                                                ? const SizedBox(width: 10)
                                                                : const SizedBox(
                                                                    width: 8,
                                                                  )),
                                                        nowDateRange.start == nowDateRange.end
                                                            ? const SizedBox()
                                                            : Container(
                                                                constraints: const BoxConstraints(minWidth: 100),
                                                                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                                                                decoration: BoxDecoration(
                                                                  color: const Color.fromARGB(255, 255, 255, 255),
                                                                  borderRadius: BorderRadius.circular(10),
                                                                  boxShadow: const [
                                                                    BoxShadow(
                                                                      color: Color.fromARGB(255, 0, 136, 255),
                                                                      offset: Offset(0, 0),
                                                                      blurRadius: 1,
                                                                    ),
                                                                  ],
                                                                ),
                                                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                                                  const Text(
                                                                    "End Date",
                                                                    style: TextStyle(color: Color.fromARGB(255, 145, 145, 145)),
                                                                  ),
                                                                  Text(
                                                                    "${nowDateRange.end.year}/${nowDateRange.end.month}/${nowDateRange.end.day}",
                                                                    style: const TextStyle(
                                                                      color: Colors.black,
                                                                      fontSize: 16,
                                                                      fontWeight: FontWeight.bold,
                                                                    ),
                                                                  ),
                                                                ]),
                                                              ),
                                                      ])),
                                                  const SizedBox(width: 10),
                                                  MediaQuery.of(context).size.width > 500
                                                      ? IconButton(
                                                          onPressed: () {
                                                            if (nowDateRange.end.subtract(const Duration(days: 1)).isAfter(DateTime.now())) {
                                                              setState(() {
                                                                SmartDialog.showToast('到底啦～～', displayTime: const Duration(milliseconds: 500));
                                                                // nowDateRange = DateTimeRange(start: nowDateRange.start.add(const Duration(days: 1)), end: nowDateRange.end.add(const Duration(days: 1)));
                                                              });
                                                            } else {
                                                              setState(() {
                                                                nowDateRange =
                                                                    DateTimeRange(start: nowDateRange.start.add(const Duration(days: 1)), end: nowDateRange.start.add(const Duration(days: 1)));
                                                              });
                                                              SmartDialog.showToast('往後一天', displayTime: const Duration(milliseconds: 500));
                                                            }
                                                          },
                                                          icon: const Icon(Icons.chevron_right))
                                                      : const SizedBox(),
                                                  MediaQuery.of(context).size.width > 500
                                                      ? GestureDetector(
                                                          child: const Icon(Icons.last_page),
                                                          onTap: () {
                                                            // 往後一個禮拜，但是不能超過今天
                                                            if (nowDateRange.end.add(const Duration(days: 7)).isAfter(DateTime.now())) {
                                                              //如果超過今天
                                                              setState(() {
                                                                //設定到前7天到今天
                                                                if (nowDateRange.start == nowDateRange.end) {
                                                                  //如果只有一天
                                                                  DateTime today = DateTime.now();
                                                                  nowDateRange = DateTimeRange(start: today.add(const Duration(days: 7)), end: today.add(const Duration(days: 7)));
                                                                } else {
                                                                  DateTime today = DateTime.now();
                                                                  nowDateRange = DateTimeRange(start: today.subtract(const Duration(days: 7)), end: today);
                                                                }
                                                              });
                                                            } else {
                                                              //如果沒有超過今天
                                                              setState(() {
                                                                if (nowDateRange.start == nowDateRange.end) {
                                                                  nowDateRange =
                                                                      DateTimeRange(start: nowDateRange.start.add(const Duration(days: 7)), end: nowDateRange.start.add(const Duration(days: 7)));
                                                                } else {
                                                                  nowDateRange =
                                                                      DateTimeRange(start: nowDateRange.start.add(const Duration(days: 7)), end: nowDateRange.end.add(const Duration(days: 7)));
                                                                }
                                                              });
                                                            }
                                                            SmartDialog.showToast('往後一個禮拜', displayTime: const Duration(milliseconds: 500));
                                                          },
                                                          onLongPress: () {
                                                            if (nowDateRange.start == nowDateRange.end) {
                                                              setState(() {
                                                                DateTime today = DateTime.now();
                                                                nowDateRange = DateTimeRange(start: today, end: today);
                                                              });
                                                            } else {
                                                              DateTime today = DateTime.now();
                                                              nowDateRange = DateTimeRange(start: today.subtract(const Duration(days: 7)), end: today);
                                                            }
                                                            SmartDialog.showToast('跳轉至今天', displayTime: const Duration(milliseconds: 500));
                                                          },
                                                        )
                                                      : const SizedBox(),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        AnimatedSwitcher(
                                            duration: const Duration(milliseconds: 500),
                                            child: showhistorychart
                                                ? AspectRatio(
                                                    aspectRatio: 1.5,
                                                    child: PageView(
                                                      onPageChanged: (int page) => {
                                                        setState(() {
                                                          nowhistorypage = page;
                                                        })
                                                      },
                                                      controller: _controllerhis,
                                                      children: [
                                                        SfCartesianChart(
                                                          zoomPanBehavior: _zoomPanBehavior,
                                                          series: <ChartSeries>[
                                                            LineSeries<dynamic, dynamic>(
                                                              dataSource: statusHistoryMap,
                                                              xValueMapper: (data, _) => data['index'],
                                                              yValueMapper: (data, _) => data['avg_current1'] * data['avg_voltage'] * 0.001,
                                                            ),
                                                            LineSeries<dynamic, dynamic>(
                                                              dataSource: statusHistoryMap,
                                                              xValueMapper: (data, _) => data['index'],
                                                              yValueMapper: (data, _) => data['avg_current2'] * data['avg_voltage'] * 0.001,
                                                            ),
                                                          ],
                                                          //線對齊
                                                          enableAxisAnimation: true,
                                                          primaryYAxis: NumericAxis(
                                                            //w顯示在數字後面
                                                            numberFormat: NumberFormat.currency(locale: 'zh_TW', symbol: '', decimalDigits: 0, customPattern: "####W"),
                                                          ),
                                                        ),
                                                        SfCartesianChart(
                                                          zoomPanBehavior: _zoomPanBehavior,
                                                          primaryXAxis: CategoryAxis(),
                                                          series: <ChartSeries>[
                                                            LineSeries<dynamic, dynamic>(
                                                              dataSource: statusHistoryMap,
                                                              xValueMapper: (data, _) => data['index'],
                                                              yValueMapper: (data, _) => data['avg_voltage'],
                                                            ),
                                                          ],
                                                          //線對齊
                                                          enableAxisAnimation: true,
                                                          primaryYAxis: NumericAxis(
                                                            //w顯示在數字後面
                                                            numberFormat: NumberFormat.currency(locale: 'zh_TW', symbol: '', decimalDigits: 1, customPattern: "####V"),
                                                          ),
                                                        ),
                                                        SfCartesianChart(
                                                          zoomPanBehavior: _zoomPanBehavior,
                                                          primaryXAxis: CategoryAxis(),
                                                          series: <ChartSeries>[
                                                            LineSeries<dynamic, dynamic>(
                                                              dataSource: statusHistoryMap,
                                                              xValueMapper: (data, _) => data['index'],
                                                              yValueMapper: (data, _) => data['avg_temp'],
                                                            ),
                                                          ],
                                                          //線對齊
                                                          enableAxisAnimation: true,
                                                          primaryYAxis: NumericAxis(
                                                            //w顯示在數字後面
                                                            numberFormat: NumberFormat.currency(locale: 'zh_TW', symbol: '', decimalDigits: 1, customPattern: "####°C"),
                                                          ),
                                                        ),
                                                      ],
                                                    ))
                                                : const SizedBox()),
                                        showhistorychart
                                            ? Container(
                                                margin: const EdgeInsets.only(top: 5, bottom: 5, left: 5, right: 5),
                                                padding: const EdgeInsets.only(top: 5, bottom: 5, left: 10, right: 10),
                                                decoration: BoxDecoration(
                                                  color: const Color.fromARGB(255, 255, 255, 255),
                                                  borderRadius: BorderRadius.circular(10),
                                                  boxShadow: const [
                                                    BoxShadow(
                                                      color: Color.fromARGB(255, 0, 0, 0),
                                                      offset: Offset(0, 0),
                                                      blurRadius: 1.0,
                                                    ),
                                                  ],
                                                ),
                                                child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.zoom_in),
                                                    onPressed: () {
                                                      //date range 日期時間縮小
                                                    },
                                                  ),
                                                  IconButton(
                                                    //zoom out
                                                    icon: const Icon(Icons.zoom_out),
                                                    onPressed: () {
                                                      //日期時間放大
                                                    },
                                                  ),
                                                ]))
                                            : const SizedBox(),
                                      ],
                                    )),
                              ],
                            ),
                          )),
                        ],
                      ),
                    )
                  : Expanded(
                      child: Column(
                      children: [
                        ElevatedButton(
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all(const Color.fromARGB(255, 255, 255, 255)),
                              foregroundColor: MaterialStateProperty.all(Colors.white),
                              textStyle: MaterialStateProperty.all(const TextStyle(color: Colors.blue, fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                            onPressed: () {
                              showSpinnerTimePicker(
                                context,
                                title: '選擇時間',
                                backgroundColor: Colors.grey[100],
                                nonSelectedTextStyle: const TextStyle(fontSize: 16, color: Colors.white),
                                selectedTextStyle: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                                titleStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                // buttonStyle: ButtonStyle(
                                //   backgroundColor: MaterialStateProperty.all(Colors.black),
                                //   foregroundColor: MaterialStateProperty.all(Colors.white),
                                //   textStyle: MaterialStateProperty.all(TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                // ),
                                buttonTextStyle: const TextStyle(color: Colors.white, fontSize: 16),
                                initTime: TimeOfDay.now(),
                                is24HourFormat: false,
                                cancelButtonLabel: "取消",
                                okButtonLabel: "確定",

                                barrierDismissible: true,
                                // ... other customization options
                              ).then((value) => {
                                    if (value != null)
                                      {
                                        setState(() {
                                          timerlist.add(timestate(time: value, status: 0));
                                        })
                                      }
                                  });
                            },
                            child: Container(padding: const EdgeInsets.all(10), child: const Text('+'))),
                        //listview scroll for timer
                        MediaQuery.removePadding(
                            removeTop: true,
                            context: context,
                            child: Container(
                                margin: const EdgeInsets.only(left: 20, right: 20),
                                height: MediaQuery.of(context).size.height * 0.5,
                                child: Expanded(
                                    child: ListView(
                                  children: List.generate(
                                    timerlist.length,
                                    (index) => Container(
                                      margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                                      padding: MediaQuery.of(context).size.width > 600 ? const EdgeInsets.fromLTRB(20, 10, 20, 10) : const EdgeInsets.fromLTRB(5, 5, 5, 5),
                                      decoration: BoxDecoration(
                                        color: Platform.isIOS ? Colors.white.withOpacity(0.8) : Colors.white.withOpacity(0.6),
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black12,
                                            offset: Offset(0, 2),
                                            blurRadius: 4.0,
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: GestureDetector(
                                                onTap: () {
                                                  showSpinnerTimePicker(
                                                    context,
                                                    title: '選擇時間',
                                                    backgroundColor: Colors.grey[100],
                                                    nonSelectedTextStyle: const TextStyle(fontSize: 16, color: Colors.white),
                                                    selectedTextStyle: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                                                    titleStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                                    // buttonStyle: ButtonStyle(
                                                    //   backgroundColor: MaterialStateProperty.all(Colors.black),
                                                    //   foregroundColor: MaterialStateProperty.all(Colors.white),
                                                    //   textStyle: MaterialStateProperty.all(TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                                    // ),
                                                    buttonTextStyle: const TextStyle(color: Colors.white, fontSize: 16),
                                                    initTime: timerlist[index].time,
                                                    is24HourFormat: false,
                                                    cancelButtonLabel: "取消",
                                                    okButtonLabel: "確定",

                                                    barrierDismissible: true,
                                                    // ... other customization options
                                                  ).then((value) => {
                                                        if (value != null)
                                                          {
                                                            setState(() {
                                                              timerlist[index].time = value;
                                                            })
                                                          }
                                                      });
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.all(10),
                                                  child: Text(
                                                    timerlist[index].time.format(context),
                                                    style: const TextStyle(fontSize: 20),
                                                  ),
                                                )),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete),
                                            onPressed: () {
                                              setState(() {
                                                timerlist.removeAt(index);
                                              });
                                            },
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                )))),
                      ],
                    )),
              Theme(
                data: Theme.of(context).copyWith(canvasColor: Colors.white.withOpacity(0.5), textTheme: Theme.of(context).textTheme.copyWith()), // sets the inactive color of the `BottomNavigationBar`
                child: BottomNavigationBar(
                  items: const <BottomNavigationBarItem>[
                    BottomNavigationBarItem(
                      icon: Icon(Icons.device_hub),
                      label: '裝置',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.timer),
                      label: '定時',
                    ),
                  ],
                  currentIndex: _selectedIndex,
                  selectedItemColor: Colors.blue,
                  onTap: _onItemTapped,
                ),
              ),
            ],
          )),
    );
  }
}

// ignore: camel_case_types
class timestate {
  TimeOfDay time;
  int status;
  timestate({required this.time, required this.status});
}
