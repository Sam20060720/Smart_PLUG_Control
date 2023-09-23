import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:flutter_ble_lib_ios_15/flutter_ble_lib.dart';
import 'package:smart_plug_control/httpreq.dart';
import 'package:smart_plug_control/intro.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_plug_control/home.dart';

String SERVICE_UUID = '4fafc201-1fb5-459e-8fcc-c5c9c331914b';
String WIFI_CONNECT_CHARACTERISTIC_UUID = "e0b4e907-097b-4081-9a72-dd72ee9f5895";
String WIFI_CONNECT_CHARACTERISTIC_UUID2 = "00001801-0000-1000-8000-00805f9b34fb";
String IDENTIFY_CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
String WIFI_LIST_CHARACTERISTIC_UUID = "d1f64a55-6fc3-44ae-9f7a-3d9a4e20e2f7";
String TOKEN_CHARACTERISTIC_UUID = "e8d4bbf7-af0d-43b5-8e3f-70a95907db68";

final info = NetworkInfo();
BleManager bleManager = BleManager();

class RegDevice extends StatefulWidget {
  const RegDevice({super.key});
  @override
  State<RegDevice> createState() => _RegDeviceState();
}

class _RegDeviceState extends State<RegDevice> {
  //bluetooth devies list
  late List<ScanResult> scanResults = [];
  late bool isScanning = true;

  @override
  void initState() {
    bleManager.destroyClient();
    bleManager.createClient();
    super.initState();

    setState(() {
      isScanning = false;
    });
    startScan();
  }

  @override
  void dispose() {
    super.dispose();
    stopScan();
    bleManager.destroyClient();
  }

  StreamSubscription<ScanResult>? scanSubscription; // 新增一個訂閱的變數
  Stream<ScanResult> getScanStream() {
    // return flutterBlue.scan(timeout: const Duration(seconds: 6));
    return bleManager.startPeripheralScan();
  }

  void setStream(Stream<ScanResult> scanStream) {
    scanSubscription = scanStream.timeout(
      const Duration(seconds: 6),
      onTimeout: (sink) {
        bleManager.stopPeripheralScan();
        sink.close(); // 在 timeout 時，關閉 Stream
      },
    ).listen((scanResult) {
      setState(() {
        //remove duplicate
        scanResults.removeWhere((element) => element.peripheral.identifier == scanResult.peripheral.identifier || (element.peripheral.name ?? '') == '');

        scanResults.add(scanResult);
        isScanning = true;
      });
    }, onDone: () {
      setState(() {
        isScanning = false;
      });
    });
  }

  void startScan() {
    scanSubscription?.cancel(); // 取消舊的訂閱
    bleManager.stopPeripheralScan();
    setStream(getScanStream()); // 設定新的訂閱
  }

// 在需要停止掃描時，呼叫此方法
  void stopScan() {
    scanSubscription?.cancel();
    bleManager.stopPeripheralScan();
  }

  void dig(String msg, bool isjum) => {
        showDialog(
            barrierDismissible: false,
            context: context,
            builder: (context) => AlertDialog(
                  title: const Text('連線失敗'),
                  content: Text(msg),
                  //cannot close by clicking outside
                  actions: [
                    TextButton(
                        onPressed: () {
                          if (isjum) {
                            Navigator.of(context).popUntil((route) => route.isFirst);
                            Navigator.pushReplacement(
                                context,
                                PageRouteBuilder(
                                    transitionDuration: const Duration(milliseconds: 200),
                                    pageBuilder: (context, animation, secondaryAnimation) {
                                      return FadeTransition(
                                        opacity: animation,
                                        child: const IntroPage(),
                                      );
                                    }));
                          } else {
                            Navigator.of(context).pop();
                          }
                        },
                        child: const Text('確定'))
                  ],
                ))
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(0, 255, 255, 255),
        elevation: 0, // 1
        title: const Text(
          "Smart PLUG",
          style: TextStyle(
            color: Color.fromARGB(255, 0, 169, 215), // 2
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color.fromARGB(255, 0, 169, 215)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
          child: Container(
              height: MediaQuery.of(context).size.height * 0.825,
              width: MediaQuery.of(context).size.width * 0.85,
              //box shadow
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    spreadRadius: 0.5,
                    blurRadius: 1,
                    offset: const Offset(0, 3), // changes position of shadow
                  ),
                ],
              ),
              child: Column(
                //上下空間平均分配
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                //allisgnment
                children: [
                  const Text("請選擇要連接的裝置", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 0, 169, 215))),
                  //bluetooth device list from scanResults
                  //refresh button
                  Container(
                    //background color
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 255, 255, 255),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    //height: scrrenheight * 0.5,
                    height: MediaQuery.of(context).size.height * 0.7,
                    width: MediaQuery.of(context).size.width * 0.7,
                    child: scanResults.isNotEmpty
                        ? ListView.builder(
                            itemCount: scanResults.length,
                            itemBuilder: (context, index) {
                              return (((scanResults[index].peripheral.name) ?? '').contains('ESP32'))
                                  ? Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: ListTile(
                                        title: Text(scanResults[index].peripheral.name ?? ''),
                                        subtitle: Text(scanResults[index].peripheral.identifier.toString()),
                                        onTap: () {
                                          //try pair
                                          Navigator.push(context, MaterialPageRoute(builder: (context) => WifiSetting(device: scanResults[index].peripheral)));
                                        },
                                      ))
                                  : const SizedBox();
                            },
                          )
                        : const Center(child: Text('找不到可連接的裝置')),
                  ),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: () {
                        setState(() {
                          if (!isScanning) {
                            stopScan();
                          }
                          startScan();
                        });
                      },
                      //text with spinner
                      child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.5,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('重新掃描裝置'),
                              const SizedBox(
                                width: 10,
                              ),
                              isScanning
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator.adaptive(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Container(),
                            ],
                          ))),
                ],
              ))),
    );
  }
}

//wifi setting page for ble device
class WifiSetting extends StatefulWidget {
  final Peripheral device;
  const WifiSetting({Key? key, required this.device}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api, no_logic_in_create_state
  _WifiSettingState createState() => _WifiSettingState(device);
}

class _WifiSettingState extends State<WifiSetting> {
  final Peripheral device;
  _WifiSettingState(this.device);

  //wifi list
  List<String> wifilist = [];
  List<String> rssilist = [];

  bool isconmected = false;
  bool isScanning = true;
  late String password;
  Timer? timer;
  HttpReq httpreq = HttpReq();

  void dig(String msg, {bool jump = true, bool ispop = true, String title = "連線失敗"}) => {
        showDialog(
            barrierDismissible: false,
            context: context,
            builder: (context) => AlertDialog(
                  title: Text(title),
                  content: Text(msg),
                  //cannot close by clicking outside
                  actions: [
                    TextButton(
                        onPressed: () {
                          if (jump) {
                            Navigator.of(context).popUntil((route) => route.isFirst);
                            Navigator.pushReplacement(
                                context,
                                PageRouteBuilder(
                                    transitionDuration: const Duration(milliseconds: 200),
                                    pageBuilder: (context, animation, secondaryAnimation) {
                                      return FadeTransition(
                                        opacity: animation,
                                        child: const RegDevice(),
                                      );
                                    }));
                          } else {
                            if (ispop) {
                              Navigator.of(context).pop();
                            }
                          }
                        },
                        child: const Text('確定'))
                  ],
                ))
      };

  @override
  void initState() {
    super.initState();
    device.isConnected().then((value) => {
          if (value) {bleManager.destroyClient(), device.disconnectOrCancelConnection()}
        });

    device.connect(timeout: const Duration(seconds: 5)).then((value) => {
          device.isConnected().then((iscon) => {
                if (iscon)
                  {
                    //discover all services and characteristics
                    device.discoverAllServicesAndCharacteristics().then((value) => {
                          device.services().then((services) => {
                                if (services[0].uuid.toString() != SERVICE_UUID && services[0].uuid.toString() != WIFI_CONNECT_CHARACTERISTIC_UUID2) {dig('不是正確的裝置')},
                                services[0].readCharacteristic(SERVICE_UUID).then((chc) => {
                                      //String.fromCharCodes(value)
                                      chc.read().then((value) => {
                                            if (!String.fromCharCodes(value).contains("ESP")) {device.disconnectOrCancelConnection(), bleManager.destroyClient(), dig('不是正確的裝置')}
                                          })
                                    })
                              })
                        })
                  }
                else
                  {
                    // print('not connected'),
                    Navigator.pop(context),
                  }
              })
        });
    //async delay
    Future.delayed(const Duration(seconds: 5), () {
      device.isConnected().then((value) => {
            if (value)
              {
                if (mounted)
                  {
                    setState(() {
                      isScanning = true;
                      isconmected = true;
                      scanWifi();
                    })
                  }
              }
            else
              {dig('連接超時 (Timeout)')}
          });
    });
  }

  @override
  void dispose() {
    super.dispose();
    device.disconnectOrCancelConnection();
    bleManager.destroyClient();
    timer?.cancel();
  }

  void scanWifi() {
    setState(() {
      isScanning = true;
    });
    device.readCharacteristic(SERVICE_UUID, WIFI_LIST_CHARACTERISTIC_UUID).then((value) => {
          value.read().then(
                (value) => {
                  //split by \n to wifi list
                  //for each line with index, a line for ssid , b line for rssi
                  setState(() {
                    wifilist.clear();
                    String.fromCharCodes(value).split('\n').asMap().forEach((index, element) {
                      if (index % 2 == 0) {
                        if (element != '') {
                          wifilist.add(element);
                          rssilist.add(String.fromCharCodes(value).split('\n')[index + 1]);
                        }
                      }
                    });
                    isScanning = false;
                  }),

                  wifilist = wifilist.map((e) => utf8.decode(e.codeUnits)).toList(),
                },
              )
        });
  }

  void showWifiPasswordDialog(String ssid) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('請輸入密碼($ssid)'),
            content: TextField(
              obscureText: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: '密碼',
              ),
              onChanged: (value) {
                setState(() {
                  password = value;
                });
              },
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('取消')),
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    connectWifi(ssid, password);
                  },
                  child: const Text('確定')),
            ],
          );
        });
  }

  void connectWifi(String ssid, String password) {
    String sendData = '$ssid\n$password';

    // ignore: no_leading_underscores_for_local_identifiers
    void _runWithErrorHandling(Future<void> Function() action) async {
      try {
        await action();
      } on BleError {
        // print(e);
        dig('連線失敗');
      }
    }

    Future<void> connect() async {
      _runWithErrorHandling(() async {
        // log("Connecting to ${peripheral.name}");
        await device.writeCharacteristic(SERVICE_UUID, WIFI_CONNECT_CHARACTERISTIC_UUID, Uint8List.fromList(sendData.codeUnits), true);

        // ignore: use_build_context_synchronously
        showDialog(
          context: context,
          builder: (context) => const AlertDialog(
            title: Text('連線中'),
            //spinner
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator.adaptive(),
                SizedBox(
                  height: 10,
                ),
                Text('請稍後'),
              ],
            ),
          ),
          barrierDismissible: false,
        );
      });
    }

    connect();
    //10s time out , check every 1s
    timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      device.readCharacteristic(SERVICE_UUID, 'WIFI_CONNECT_CHARACTERISTIC_UUID').then((chc) => {
            chc.read().then((value) => {
                  if (String.fromCharCodes(value) == "CONNECTED")
                    {
                      t.cancel(),
                      Navigator.pop(context), //pop waiting dialog
                      showDialog(
                        context: context,
                        builder: (context) => const AlertDialog(
                          title: Text('取得裝置資料中'),
                          //spinner
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator.adaptive(),
                              SizedBox(
                                height: 10,
                              ),
                              Text('請稍後'),
                            ],
                          ),
                        ),
                        barrierDismissible: false,
                      ),
                      timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
                        device.readCharacteristic(SERVICE_UUID, 'WIFI_CONNECT_CHARACTERISTIC_UUID').then((chc) => {
                              chc.read().then((value) => {
                                    if (String.fromCharCodes(value) == "CONNECTED")
                                      {
                                        t.cancel(),
                                        device.readCharacteristic(SERVICE_UUID, TOKEN_CHARACTERISTIC_UUID).then((chcToken) => {
                                              chcToken.read().then((Uint8List chartok) {
                                                if (String.fromCharCodes(chartok) != "") {
                                                  Navigator.pop(context); //pop waiting dialog
                                                  httpreq.getDevice(String.fromCharCodes(chartok)).then((thedevice) => {
                                                        SharedPreferences.getInstance().then((SharedPreferences sharedPreference) {
                                                          List<String> listString = sharedPreference.getStringList('devices') ?? [];
                                                          listString.add(jsonEncode(thedevice.toJson()));
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
                                                        }),
                                                        //Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const HomePage()), (Route<dynamic> route) => false)
                                                      });
                                                }
                                              })
                                            }),
                                      }
                                    else if (t.tick == 20)
                                      {
                                        t.cancel(),
                                        Navigator.pop(context), //pop waiting dialog
                                        dig('連線失敗', jump: false)
                                      }
                                  })
                            });
                      }),
                    }
                  else if (t.tick == 10)
                    {
                      t.cancel(),
                      Navigator.pop(context), //pop waiting dialog
                      dig('連線失敗', jump: false)
                    }
                })
          });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //don't resize at keyboard show
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(0, 255, 255, 255),
        elevation: 0, // 1
        title: const Text(
          "Smart PLUG",
          style: TextStyle(
            color: Color.fromARGB(255, 0, 169, 215), // 2
          ),
        ),
      ),
      body: Center(
        child: Container(
          height: MediaQuery.of(context).size.height * 0.85,
          width: MediaQuery.of(context).size.width * 0.85,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                spreadRadius: 0.5,
                blurRadius: 1,
                offset: const Offset(0, 3), // changes position of shadow
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              //top and bottom padding
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text("請選擇要連接的WiFi", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 0, 169, 215))),
              ),

              //bluetooth device list from scanResults
              //refresh button
              Container(
                //background color
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 255, 255, 255),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                //height: scrrenheight * 0.5,
                height: MediaQuery.of(context).size.height * 0.7,
                width: MediaQuery.of(context).size.width * 0.7,
                child: wifilist.isNotEmpty
                    ? ListView.builder(
                        itemCount: wifilist.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(wifilist[index]),
                            subtitle: Text('RSSI: ${rssilist[index]} dbm'),
                            onTap: () {
                              showWifiPasswordDialog(wifilist[index]);
                            },
                          );
                        },
                      )
                    : const Center(child: Text('找不到可連接的WiFi')),
              ),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: () {
                    setState(() {
                      if (!isScanning) {
                        scanWifi();
                      }
                    });
                  },
                  //text with spinner
                  child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.5,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('重新掃描WiFi'),
                          isScanning ? const SizedBox(width: 10) : Container(),
                          isScanning
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator.adaptive(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Container(),
                        ],
                      ))),
            ],
          ),
        ),
        //spinner
      ),
    );
  }
}

// ignore: camel_case_types
class backg extends CustomPainter {
  double animvalue;

  backg(this.animvalue);

  @override
  void paint(Canvas canvas, Size size) {
    final wight = size.width;
    final height = size.height;
    Paint paint = Paint();

    Path mBG = Path();
    mBG.addRect(Rect.fromLTRB(0, 0, wight, height));
    paint.color = const Color.fromARGB(0, 0, 0, 0);
    canvas.drawPath(mBG, paint);

    Path mPath = Path();
    mPath.moveTo(0, height * 0.2);
    mPath.quadraticBezierTo(wight * 0.1, height * 0.7, wight, height * 0.8);

    mPath.lineTo(wight, height);
    mPath.lineTo(0, height);
    mPath.close();
    paint.color = const Color.fromARGB(162, 162, 188, 224);
    canvas.drawPath(mPath, paint);
    mPath.close();

    Path m2Path = Path();
    m2Path.moveTo(0, height * 0.6);
    m2Path.quadraticBezierTo(wight * 0.1, height * 0.7, wight, height * 0.8);

    m2Path.lineTo(wight, height);
    m2Path.lineTo(0, height);
    m2Path.close();
    paint.color = const Color.fromARGB(254, 162, 188, 224);
    canvas.drawPath(m2Path, paint);
    m2Path.close();

    final progress = const Cubic(.24, .13, .17, 1.03).transform(animvalue);
    final radius = lerpDouble(0, 1500, progress)!;
    final m3Path = Path();
    m3Path.addOval(Rect.fromCircle(
      center: Offset(wight - 50, height - 50),
      radius: radius,
    ));
    final bgPaint = Paint()..color = const Color.fromARGB(255, 255, 255, 255);
    canvas.drawPath(m3Path, bgPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
