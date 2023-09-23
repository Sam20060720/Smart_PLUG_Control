import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:smart_plug_control/httpreq.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:smart_plug_control/intro.dart';
import 'package:smart_plug_control/devices.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late List<Device> devices = [];
  bool serverError = false;
  late Timer timer;
  // ignore: non_constant_identifier_names
  late Timer timer_setting;
  // List<String> images = ["assets/images/background/bg1.avif", "assets/images/background/bg2.avif", "assets/images/background/bg4.avif", "assets/images/background/bg5.avif", "assets/images/background/bg6.avif", "assets/images/background/bg7.avif", "assets/images/background/bg8.jpeg", "assets/images/background/bg9.avif", "assets/images/background/bg10.jpeg", "assets/images/background/bg11.jpeg"];
  late String imgrandom = "assets/images/background/bg7.jpg";

  @override
  void initState() {
    SharedPreferences.getInstance().then((SharedPreferences sharedPreference) {
      List<String> listString = sharedPreference.getStringList('devices') ?? [];
      devices = listString.map((item) => Device.fromJson(json.decode(item))).toList();

      //verify setting
      for (var device in devices) {
        HttpReq().getSetting(device.token).then((setting) {
          if (setting == "error") {
          } else {
            if (device.setting != setting) {
              device.setting = setting;
              SharedPreferences.getInstance().then((SharedPreferences sharedPreference) {
                List<String> listString = sharedPreference.getStringList('devices') ?? [];
                listString.removeWhere((element) => json.decode(element)['token'] == device.token);
                listString.add(json.encode(device.toJson()));
                sharedPreference.setStringList('devices', listString);
              });
            }
          }
        });
      }
      setState(() {});
    });
    // ignore: unused_local_variable
    timer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      if (ModalRoute.of(context)!.isCurrent) {
        for (var device in devices) {
          HttpReq().getStat(device.token).then((devstat) {
            if (devstat == "SERVER ERROR") {
              if (mounted) {
                setState(() {
                  device.status = "OFFLINE";
                  serverError = true;
                });
              }
            } else {
              if (mounted) {
                setState(() {
                  serverError = false;
                  if (devstat.runtimeType != String) {
                    device.rawdata = devstat;
                    device.status = "ONLINE";
                  } else {
                    device.status = "OFFLINE";
                  }
                });
              }
            }
          });
        }
      }
      // update device status
    });

    //update device setting
    timer_setting = Timer.periodic(const Duration(milliseconds: 5000), (timer) {
      if (ModalRoute.of(context)!.isCurrent) {
        for (var device in devices) {
          HttpReq().getSetting(device.token).then((setting) {
            if (setting == "error") {
            } else {
              if (device.setting != setting) {
                device.setting = setting;
                SharedPreferences.getInstance().then((SharedPreferences sharedPreference) {
                  List<String> listString = sharedPreference.getStringList('devices') ?? [];
                  listString.removeWhere((element) => json.decode(element)['token'] == device.token);
                  listString.add(json.encode(device.toJson()));
                  sharedPreference.setStringList('devices', listString);
                });
              }
            }
          });
        }
      } else {
        //print("not top");
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    timer.cancel();
    timer_setting.cancel();
  }

  @override
  Widget build(BuildContext context) {
    //從assets/images/background/隨機選擇一張圖片
    //使用抓取assets/images/background/的檔案名稱

    // ignore: unused_local_variable
    return Scaffold(
        resizeToAvoidBottomInset: false,
        //no appbar
        appBar: null,
        body: GestureDetector(
          onLongPress: () {
            setState(() {
              int x = Random().nextInt(7) + 1;
              imgrandom = "assets/images/background/bg$x.jpg";
            });
          },
          child: Container(
              decoration: BoxDecoration(
                  image: DecorationImage(
                //image 靠右上
                //random from assets/images/background/

                image: AssetImage(imgrandom),
                fit: BoxFit.cover,
              )),
              child: Column(
                children: [
                  ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Container(
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
                                    icon: const Icon(Icons.home),
                                    onPressed: () {
                                      //jump to register new
                                      SmartDialog.showToast("由『』製作");
                                    },
                                  ),
                                  Expanded(
                                    child: Container(
                                      alignment: Alignment.center,
                                      child: Text(
                                        !serverError ? "Smart PLUG" : "Smart PLUG (Server Error)",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                          color: !serverError ? const Color.fromARGB(255, 0, 0, 0) : Colors.red,
                                        ),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () {
                                      //jump to register new
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const ChoicePage()),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          )),
                    ),
                  ),
                  Expanded(
                    child: CustomScrollView(
                      slivers: [
                        //server error
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              Device device = devices[index];
                              return device.type == "PLUGDUAL"
                                  ? plugDual(
                                      device: device,
                                    )
                                  : device.type == "PLUGTEMP"
                                      ? plugTemp(
                                          device: device,
                                        )
                                      : Container();
                            },
                            childCount: devices.length,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )),
        ));
  }
}
