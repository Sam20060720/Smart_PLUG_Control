import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:smart_plug_control/device_page.dart';
import 'httpreq.dart';
import 'package:smart_plug_control/home.dart';
import 'package:smart_plug_control/line.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

import 'dart:convert';

Future<void> settingDialog(BuildContext context, devicePage widget) async {
  //設定選單Dialog
  final TextEditingController nameinput = TextEditingController();
  late double safeMinTemp = widget.device.setting['safeMinTemp'] == null ? 20 : double.tryParse(widget.device.setting['safeMinTemp']) ?? 20;
  late double safeMaxTemp = widget.device.setting['safeMaxTemp'] == null ? 80 : double.tryParse(widget.device.setting['safeMaxTemp']) ?? 80;
  late double safeMinVoltage = widget.device.setting['safeMinVoltage'] == null ? 80 : double.tryParse(widget.device.setting['safeMinVoltage']) ?? 80;
  late double safeMaxVoltage = widget.device.setting['safeMaxVoltage'] == null ? 250 : double.tryParse(widget.device.setting['safeMaxVoltage']) ?? 250;
  late double safeMaxWatt = widget.device.setting['safeMaxWatt'] == null ? 1500 : double.tryParse(widget.device.setting['safeMaxWatt']) ?? 1500;
  final TextEditingController passwordoldinput = TextEditingController();
  final TextEditingController passwordnewinput = TextEditingController();
  final TextEditingController passwordverifyinput = TextEditingController();
  bool showpassword = false;

  await showDialog(
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
}

Widget topNav(BuildContext context, devicePage widget, bool serverError) {
  return Container(
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
                  settingDialog(context, widget);
                },
              ),
            ],
          ),
        ],
      ));
}

Widget chartOffline() {
  return Container(
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
      )));
}

Widget motionText(context, text, isnow, onpress) {
  return TextButton(
    style: MediaQuery.of(context).size.width < 600
        ? TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
          )
        : TextButton.styleFrom(),
    child: Text(
      text,
      style: TextStyle(color: (isnow ? Colors.black : Colors.grey), fontSize: (isnow ? 25 : 10)),
    ),
    onPressed: () {
      onpress();
    },
  );
}

EdgeInsets EdgeOnly(topi, bottomi, lefti, righti) {
  return EdgeInsets.only(top: topi, bottom: bottomi, left: lefti, right: righti);
}
