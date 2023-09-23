import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_plug_control/home.dart';
import 'package:flutter_ble_lib_ios_15/flutter_ble_lib.dart';
import 'dart:async';
import "package:smart_plug_control/httpreq.dart";
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

BleManager bleManager = BleManager();

class AddDevice extends StatefulWidget {
  const AddDevice({super.key});
  @override
  State<AddDevice> createState() => _AddDeviceState();
}

class _AddDeviceState extends State<AddDevice> {
  //bluetooth devies list
  late List<ScanResult> scanResults = [];
  //last scan time
  late DateTime lastScanTime = DateTime.now();
  late bool isScanning = true;
  //create controller
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    bleManager.destroyClient();
    bleManager.createClient();
    super.initState();

    setState(() {
      isScanning = true;
    });
    startScan();

    //ask permission
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
      scanResults.removeWhere((element) => element.peripheral.identifier == scanResult.peripheral.identifier || (element.peripheral.name ?? '') == "");
      if ((scanResult.peripheral.name ?? "") != "") {
        scanResults.add(scanResult);
      }
      isScanning = true;
      if (DateTime.now().difference(lastScanTime).inSeconds > 3) {
        setState(() {
          lastScanTime = DateTime.now();
        });
      }
    }, onDone: () {
      setState(() {
        isScanning = false;
      });
    });
  }

  @override
  void dispose() {
    scanSubscription?.cancel();
    bleManager.stopPeripheralScan();
    super.dispose();
  }

  void startScan() {
    scanSubscription?.cancel(); // 取消舊的訂閱
    bleManager.stopPeripheralScan();

    setStream(getScanStream()); // 設定新的訂閱
    setState(() {
      isScanning = true;
    });
  }

// 在需要停止掃描時，呼叫此方法
  void stopScan() {
    scanSubscription?.cancel();
    bleManager.stopPeripheralScan();
    setState(() {
      isScanning = false;
    });
  }

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
                    height: MediaQuery.of(context).size.height * 0.6,
                    width: MediaQuery.of(context).size.width * 0.7,
                    child: scanResults.isNotEmpty
                        ? ListView.builder(
                            itemCount: scanResults.length,
                            // ignore: body_might_complete_normally_nullable
                            itemBuilder: (context, index) {
                              Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: ListTile(
                                    title: Text(scanResults[index].peripheral.name ?? ''),
                                    subtitle: Text(scanResults[index].peripheral.identifier.toString()),
                                    onTap: () {
                                      //show dialog to input 6 digit code
                                      showDialog(
                                          barrierDismissible: false,
                                          context: context,
                                          builder: (context) => AlertDialog(
                                                title: const Text('請輸入6位數密碼'),
                                                content: TextField(
                                                  controller: _controller,
                                                  keyboardType: TextInputType.number,
                                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                                  maxLength: 6,
                                                  decoration: const InputDecoration(hintText: '請輸入6位數密碼'),
                                                ),
                                                //cannot close by clicking outside
                                                actions: [
                                                  TextButton(
                                                      onPressed: () {
                                                        Navigator.of(context).pop();
                                                      },
                                                      child: const Text('取消')),
                                                  TextButton(
                                                      onPressed: () {
                                                        //_controller.text
                                                      },
                                                      child: const Text('確定'))
                                                ],
                                              ));
                                    },
                                  ));
                            },
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Center(child: Text('找不到可連接的裝置')),
                              const SizedBox(
                                width: 10,
                              ),
                              //button to show Tutorial dialog
                              ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  ),
                                  onPressed: () {
                                    showDialog(
                                        barrierDismissible: false,
                                        context: context,
                                        builder: (context) => AlertDialog(
                                              title: const Text('教學'),
                                              content: const Text('請先將裝置進入配對模式'),
                                              //cannot close by clicking outside
                                              actions: [
                                                TextButton(
                                                    onPressed: () {
                                                      Navigator.of(context).pop();
                                                    },
                                                    child: const Text('確定'))
                                              ],
                                            ));
                                  },
                                  //question mark icon
                                  child: const Icon(Icons.help_outline, color: Colors.white))
                            ],
                          ),
                  ),
                  Column(
                    children: [
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          onPressed: () {
                            if (isScanning) {
                              stopScan();
                            } else {
                              startScan();
                            }
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
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          onPressed: () {
                            //show dialog to input 6 digit code
                            showDialog(
                                barrierDismissible: false,
                                context: context,
                                builder: (context) => AlertDialog(
                                      title: const Text('請輸入6位數密碼'),
                                      content: TextField(
                                        controller: _controller,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                        maxLength: 6,
                                        decoration: const InputDecoration(hintText: '請輸入6位數密碼'),
                                      ),
                                      //cannot close by clicking outside
                                      actions: [
                                        TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: const Text('取消')),
                                        TextButton(
                                            onPressed: () {
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
                                                      Text('與伺服器通訊中'),
                                                    ],
                                                  ),
                                                ),
                                                barrierDismissible: false,
                                              );
                                              HttpReq().getReqToken(_controller.text).then((dynamic thedevice) {
                                                if (thedevice != "error" && thedevice != "server error") {
                                                  Navigator.pop(context);
                                                  SharedPreferences.getInstance().then((SharedPreferences sharedPreference) {
                                                    if (sharedPreference.getStringList('devices') == null) {
                                                      sharedPreference.setStringList('devices', []);
                                                    } else {
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
                                                    }
                                                  });
                                                } else if (thedevice == "error") {
                                                  Navigator.pop(context);
                                                  showDialog(
                                                      barrierDismissible: false,
                                                      context: context,
                                                      builder: (context) => AlertDialog(
                                                            title: const Text('錯誤'),
                                                            content: const Text('驗證錯誤'),
                                                            //cannot close by clicking outside
                                                            actions: [
                                                              TextButton(
                                                                  onPressed: () {
                                                                    Navigator.of(context).pop();
                                                                  },
                                                                  child: const Text('確定'))
                                                            ],
                                                          ));
                                                } else if (thedevice == "server error") {
                                                  Navigator.pop(context);
                                                  showDialog(
                                                      barrierDismissible: false,
                                                      context: context,
                                                      builder: (context) => AlertDialog(
                                                            title: const Text('錯誤'),
                                                            content: const Text('伺服器錯誤'),
                                                            //cannot close by clicking outside
                                                            actions: [
                                                              TextButton(
                                                                  onPressed: () {
                                                                    Navigator.of(context).pop();
                                                                  },
                                                                  child: const Text('確定'))
                                                            ],
                                                          ));
                                                }
                                              });
                                            },
                                            child: const Text('確定'))
                                      ],
                                    ));
                          },
                          child: SizedBox(
                              width: MediaQuery.of(context).size.width * 0.5,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('使用配對碼'),
                                ],
                              ))),
                    ],
                  )
                ],
              ))),
    );
  }
}
