import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:smart_plug_control/httpreq.dart';
import 'package:switcher_xlive/switcher_xlive.dart';
import 'package:smart_plug_control/device_page.dart';
import 'package:flutter_tilt/flutter_tilt.dart';

// ignore: camel_case_types
class plugDual extends StatefulWidget {
  const plugDual({Key? key, required this.device}) : super(key: key);
  final Device device;

  @override
  // ignore: library_private_types_in_public_api
  _plugDualState createState() => _plugDualState();
}

// ignore: camel_case_types
class _plugDualState extends State<plugDual> {
  late double voltage = widget.device.rawdata['voltage'] == null ? 0.0 : widget.device.rawdata['voltage'].toDouble();
  late double current1 = widget.device.rawdata['current1'] == null ? 0.0 : widget.device.rawdata['current1'].toDouble();
  late double current2 = widget.device.rawdata['current2'] == null ? 0.0 : widget.device.rawdata['current2'].toDouble();
  late double temp = widget.device.rawdata['temp'] == null ? 0.0 : widget.device.rawdata['temp'].toDouble();
  late bool switch1 = widget.device.rawdata['status'] == "0" || widget.device.rawdata['status'] == "2" ? true : false;
  late bool switch2 = widget.device.rawdata['status'] == "0" || widget.device.rawdata['status'] == "3" ? true : false;

  late bool serverError = false;

  late Timer timer;
  late BuildContext maincontext;
  late bool isSwitched = false;

  @override
  void initState() {
    timer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      // update device status
      if (mounted) {
        setState(() {
          if (widget.device.status == "OFFLINE") {
            serverError = true;
          } else {
            serverError = false;
            widget.device.status = "ONLINE";
            voltage = widget.device.rawdata['voltage'] == null ? 0.0 : widget.device.rawdata['voltage'].toDouble();
            current1 = widget.device.rawdata['current1'] == null ? 0.0 : widget.device.rawdata['current1'].toDouble();
            current2 = widget.device.rawdata['current2'] == null ? 0.0 : widget.device.rawdata['current2'].toDouble();
            temp = widget.device.rawdata['temp'] == null ? 0.0 : widget.device.rawdata['temp'].toDouble();

            //0 ONON
            //1 OFFOFF
            //2 ONOFF
            //3 OFFON
            switch1 = widget.device.rawdata['status'].toString() == "0" || widget.device.rawdata['status'].toString() == "2" ? true : false;
            switch2 = widget.device.rawdata['status'].toString() == "0" || widget.device.rawdata['status'].toString() == "3" ? true : false;
          }
          if (isSwitched) {
            isSwitched = false;
            Navigator.of(maincontext).pop();
          }
        });
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    timer.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Tilt(
        child: GestureDetector(
            // When the child is tapped, show a snackbar.
            onTap: () {
              // is the  page that open is more than 1, pop it
              if (Navigator.of(context).canPop()) {
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => devicePage(device: widget.device, deviceCard: widget //set tapable to false
                        ),
                  ),
                );
              }

              //show device page
            },
            child: Container(
                margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                //if screen size is small, set padding to 0
                padding: MediaQuery.of(context).size.width < 600 ? const EdgeInsets.fromLTRB(0, 10, 0, 10) : const EdgeInsets.fromLTRB(20, 10, 20, 10),
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
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                    child: Column(
                      children: [
                        Row(children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                                child: Text(
                                  widget.device.setting['name'],
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              GestureDetector(
                                child: Padding(padding: const EdgeInsets.fromLTRB(10, 0, 0, 0), child: Image.asset('assets/images/devices/plugdual.png', width: 80, height: 80)),
                                onLongPress: () => {
                                  //pop icon drawer that has many icons
                                },
                              )
                            ],
                          ),
                          const Spacer(
                            flex: 1,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(Icons.link),
                                  const SizedBox(width: 10),
                                  Text(
                                    widget.device.status,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(Icons.power),
                                  const SizedBox(width: 10),
                                  Text(
                                    (widget.device.status == "OFFLINE") ? "--" : '${voltage}V',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(Icons.thermostat),
                                  const SizedBox(width: 10),
                                  Text(
                                    (widget.device.status == "OFFLINE") ? "--" : '$temp℃',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ]),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.power),
                            const SizedBox(width: 10),
                            const Text(
                              "插座1",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(
                              flex: 1,
                            ),
                            const Icon(Icons.bolt),
                            Text(
                              (widget.device.status == "OFFLINE") ? "--" : '${(current1 * voltage * 0.001).toStringAsFixed(2)}W',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(
                              flex: 1,
                            ),
                            SwitcherXlive(
                              value: switch1,
                              onChanged: (value) {
                                //0 ONON
                                //1 OFFOFF
                                //2 ONOFF
                                //3 OFFON
                                if (widget.device.status != "OFFLINE") {
                                  maincontext = context;
                                  isSwitched = true;
                                  //show loading
                                  showDialog(
                                      barrierDismissible: false,
                                      context: context,
                                      builder: (BuildContext context) => AlertDialog(
                                            title: const Text("設定中"),
                                            content: SizedBox(
                                              height: MediaQuery.of(context).size.height * 0.1,
                                              width: MediaQuery.of(context).size.width * 0.1,
                                              child: const Center(child: CircularProgressIndicator.adaptive()),
                                            ),
                                          ));
                                  if (value) {
                                    //if switch1 set to on : 0/2
                                    if (switch2) {
                                      // if switch2 is on : 0/3
                                      // > 0
                                      HttpReq().setStat(widget.device.token, "0").then((value) {
                                        setState(() {
                                          switch1 = true;
                                          switch2 = true;
                                        });
                                      });
                                    }
                                    //if switch2 is off : 1/2
                                    else {
                                      HttpReq().setStat(widget.device.token, "2").then((value) {
                                        setState(() {
                                          switch1 = true;
                                          switch2 = false;
                                        });
                                      });
                                    }
                                  } else {
                                    //if switch1 set to off : 1/3
                                    if (switch2) {
                                      //if switch2 is on : 0/3
                                      // > 3
                                      HttpReq().setStat(widget.device.token, "3").then((value) {
                                        setState(() {
                                          switch1 = false;
                                          switch2 = true;
                                        });
                                      });
                                    }
                                    //if switch2 is off : 1/2
                                    // > 1
                                    else {
                                      HttpReq().setStat(widget.device.token, "1").then((value) {
                                        setState(() {
                                          switch1 = false;
                                          switch2 = false;
                                        });
                                      });
                                    }
                                  }
                                } else {
                                  SmartDialog.showToast("裝置離線");
                                }
                              },
                              unActiveColor: Colors.grey,
                              activeColor: Colors.blue,
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Icons.power),
                            const SizedBox(width: 10),
                            const Text(
                              "插座2",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(
                              flex: 1,
                            ),
                            const Icon(Icons.bolt),
                            Text(
                              (widget.device.status == "OFFLINE") ? "--" : '${(current2 * voltage * 0.001).toStringAsFixed(2)}W',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(
                              flex: 1,
                            ),
                            SwitcherXlive(
                              value: switch2,
                              onChanged: (value) {
                                //0 ONON
                                //1 OFFOFF
                                //2 ONOFF
                                //3 OFFON
                                if (widget.device.status != "OFFLINE") {
                                  maincontext = context;
                                  isSwitched = true;
                                  showDialog(
                                      barrierDismissible: false,
                                      context: context,
                                      builder: (BuildContext context) => AlertDialog(
                                            title: const Text("設定中"),
                                            content: SizedBox(
                                              height: MediaQuery.of(context).size.height * 0.1,
                                              width: MediaQuery.of(context).size.width * 0.1,
                                              child: const Center(child: CircularProgressIndicator.adaptive()),
                                            ),
                                          ));
                                  if (value) {
                                    //if switch2 set to on : 0/3
                                    if (switch1) {
                                      // if switch1 is on : 0/2
                                      // > 0
                                      HttpReq().setStat(widget.device.token, "0").then((value) {
                                        setState(() {
                                          switch1 = true;
                                          switch2 = true;
                                        });
                                      });
                                    }
                                    //if switch1 is off : 1/3
                                    else {
                                      HttpReq().setStat(widget.device.token, "3").then((value) {
                                        setState(() {
                                          switch1 = false;
                                          switch2 = true;
                                        });
                                      });
                                    }
                                  } else {
                                    //if switch2 set to off : 1/2
                                    if (switch1) {
                                      //if switch1 is on : 0/2
                                      // > 2
                                      HttpReq().setStat(widget.device.token, "2").then((value) {
                                        setState(() {
                                          switch1 = true;
                                          switch2 = false;
                                        });
                                      });
                                    }
                                    //if switch1 is off : 1/3
                                    // > 1
                                    else {
                                      HttpReq().setStat(widget.device.token, "1").then((value) {
                                        setState(() {
                                          switch1 = false;
                                          switch2 = false;
                                        });
                                      });
                                    }
                                  }
                                } else {
                                  SmartDialog.showToast("裝置離線");
                                }
                              },
                              unActiveColor: Colors.grey,
                              activeColor: Colors.blue,
                            ),
                          ],
                        ),
                        //build two switches
                      ],
                    )))));
  }
}

// ignore: camel_case_types
class plugTemp extends StatefulWidget {
  const plugTemp({Key? key, required this.device}) : super(key: key);

  final Device device;

  @override
  // ignore: library_private_types_in_public_api
  _plugTempState createState() => _plugTempState();
}

// ignore: camel_case_types
class _plugTempState extends State<plugTemp> {
  late double voltage = widget.device.rawdata['voltage'] == null ? 0.0 : widget.device.rawdata['voltage'].toDouble();
  late double current1 = widget.device.rawdata['current1'] == null ? 0.0 : widget.device.rawdata['current1'].toDouble();
  late double temp = widget.device.rawdata['temp'] == null ? 0.0 : widget.device.rawdata['temp'].toDouble();
  late bool switch1 = widget.device.rawdata['status'] == "0" || widget.device.rawdata['status'] == "2" ? true : false;
  late double humi = widget.device.rawdata['humi'] == null ? 0.0 : widget.device.rawdata['humi'].toDouble();
  late double tempPLUG = widget.device.rawdata['tempPLUG'] == null ? 0.0 : widget.device.rawdata['tempPLUG'].toDouble();

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              offset: Offset(0, 2),
              blurRadius: 4.0,
            ),
          ],
        ),
        child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: Column(
              children: [
                Row(children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                        child: Text(
                          widget.device.setting['name'],
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      GestureDetector(
                        child: Padding(padding: const EdgeInsets.fromLTRB(10, 0, 0, 0), child: Image.asset('assets/images/devices/plugtemp.png', width: 80, height: 80)),
                        onLongPress: () => {},
                      )
                    ],
                  ),
                  const Spacer(
                    flex: 1,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          (widget.device.status == "OFFLINE") ? const Icon(Icons.link_off) : const Icon(Icons.link),
                          const SizedBox(width: 10),
                          Text(
                            widget.device.status,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.power),
                          const SizedBox(width: 10),
                          Text(
                            (widget.device.status == "OFFLINE") ? "--" : '${voltage}V',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.thermostat),
                          const SizedBox(width: 10),
                          Text(
                            (widget.device.status == "OFFLINE") ? "--" : '$tempPLUG℃',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ]),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Spacer(
                      flex: 1,
                    ),
                    const FaIcon(
                      FontAwesomeIcons.temperatureQuarter,
                      size: 18,
                    ),
                    const SizedBox(
                      width: 5,
                    ),
                    Text(
                      (widget.device.status == "OFFLINE") ? "--" : '$temp℃',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(
                      flex: 2,
                    ),
                    const FaIcon(
                      FontAwesomeIcons.droplet,
                      size: 18,
                    ),
                    const SizedBox(
                      width: 5,
                    ),
                    Text(
                      (widget.device.status == "OFFLINE") ? "--" : '$humi%',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(
                      flex: 1,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.power),
                    const SizedBox(width: 10),
                    const Text(
                      "插座",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(
                      flex: 1,
                    ),
                    const Icon(Icons.bolt),
                    Text(
                      (widget.device.status == "OFFLINE") ? "--" : '${(current1 * voltage * 0.001).toStringAsFixed(2)}W',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(
                      flex: 1,
                    ),
                    SwitcherXlive(
                      value: switch1,
                      onChanged: (value) {
                        if (widget.device.status != "OFFLINE") {
                          if (value) {
                            HttpReq().setStat(widget.device.token, "1").then((value) {
                              setState(() {});
                            });
                          } else {
                            HttpReq().setStat(widget.device.token, "0").then((value) {
                              setState(() {});
                            });
                          }
                        }
                      },
                      unActiveColor: Colors.grey,
                      activeColor: Colors.blue,
                    ),
                  ],
                ),
              ],
            )));
  }
}
