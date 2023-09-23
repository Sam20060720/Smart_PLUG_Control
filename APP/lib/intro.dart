import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smart_plug_control/register_new.dart';
import 'package:smart_plug_control/add_old.dart';
import 'package:smart_plug_control/home.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  late AnimationController _animationControllerbg;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));

    _animationControllerbg = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

    _animation = Tween(begin: -0.2, end: 0.2).animate(_animationController)
      ..addListener(() {
        setState(() {});
      });

    _animationController.forward().whenComplete(() {
      _animationController.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _animationControllerbg.dispose();
    super.dispose();
  }

  void dig(String msg) => {
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
                          Navigator.of(context).pop();
                        },
                        child: const Text('確定'))
                  ],
                ))
      };

  Future<bool> getPermission() async {
    //check permission
    //for get permission in [locationWhenInUse, bluetooth, bluetoothScan, bluetoothConnect]

    var permission = [Permission.nearbyWifiDevices, Permission.location, Permission.locationWhenInUse, Permission.bluetooth, Permission.bluetoothScan, Permission.bluetoothConnect, Permission.bluetoothAdvertise];
    bool issuccget = true;

    for (var i = 0; i < permission.length; i++) {
      var status = await permission[i].status;
      if (status.isGranted) {
        // print('permission granted');
      } else {
        // print('permission not granted');
        var result = await permission[i].request();
        if (result.isGranted) {
          // print('permission granted');
        } else {
          // print('permission not granted');
          // dig('請開啟權限');
          // openAppSettings();
          // issuccget = false;
          break;
        }
      }
    }
    return issuccget;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(0, 255, 255, 255),
          elevation: 0, // 1
          //in center
          centerTitle: true,
          title: const Text(
            "Smart PLUG",
            style: TextStyle(
              color: Color.fromARGB(255, 0, 169, 215), // 2
            ),
          ),
          //skip button
        ),
        body: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: AnimatedBuilder(
            animation: _animationControllerbg,
            builder: (context, snapshot) {
              return Stack(children: [
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(50, 70, 50, 50),
                      child: Row(
                        children: [
                          const Spacer(),
                          Column(
                            children: [
                              Image.asset('assets/images/welcome.png',
                                  //if device rotate
                                  width: MediaQuery.of(context).size.width * 0.6 * (MediaQuery.of(context).orientation == Orientation.portrait ? 1 : 0.5)),
                              const Text('歡迎使用',
                                  style: TextStyle(
                                      //blod
                                      fontWeight: FontWeight.bold,
                                      fontSize: 40,
                                      color: Color.fromARGB(255, 0, 169, 215)))
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
                CustomPaint(
                  size: Size.infinite,
                  painter: backg(_animationControllerbg.value), // 背景動畫的繪製器
                ),
                Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Spacer(),
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                            child: IconButton(
                              iconSize: 40,
                              icon: Transform.translate(
                                offset: const Offset(0, 0).translate(-_animation.value * 20, 0.0),
                                child: const Icon(
                                  Icons.arrow_forward,
                                  color: Colors.black,
                                ),
                              ),
                              onPressed: () {
                                _animationControllerbg.forward().whenComplete(() {
                                  //nav with fade animation
                                  getPermission().then((value) => {
                                        if (value)
                                          {
                                            Navigator.push(
                                                context,
                                                PageRouteBuilder(
                                                    transitionDuration: const Duration(milliseconds: 200),
                                                    pageBuilder: (context, animation, secondaryAnimation) {
                                                      return FadeTransition(
                                                        opacity: animation,
                                                        child: const ChoicePage(),
                                                      );
                                                    })).then((value) => _animationControllerbg.reverse())
                                          }
                                      });
                                });

                                // custompaint
                              },
                            ),
                          ),
                        ],
                      ),
                    )),
              ]);
            },
          ),
        ));
  }
}

//new page for choice register new device or add device
class ChoicePage extends StatefulWidget {
  const ChoicePage({super.key});

  @override
  State<ChoicePage> createState() => _ChoicePageState();
}

class _ChoicePageState extends State<ChoicePage> {
  @override
  Widget build(BuildContext context) {
    //choice page
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(0, 255, 255, 255),
        elevation: 0, // 1
        title: const Text(
          textAlign: TextAlign.center,
          "Smart PLUG",
          style: TextStyle(),
        ),
        //skip button in left
        actions: [
          TextButton(
              onPressed: () {
                //nav pop with fade animation and jump to homePage
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
              },
              child: const Text(
                '跳過',
              ))
        ],
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
                  const Text("裝置設定", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 0, 169, 215))),
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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          //設定新裝置
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                      transitionDuration: const Duration(milliseconds: 200),
                                      pageBuilder: (context, animation, secondaryAnimation) {
                                        return SlideTransition(
                                          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(animation),
                                          child: const RegDevice(),
                                        );
                                      }));
                            },
                            child: Container(
                              height: MediaQuery.of(context).size.height * 0.2,
                              width: MediaQuery.of(context).size.width * 0.6,
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 0, 169, 215),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(
                                  child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.settings,
                                    color: Color.fromARGB(255, 255, 255, 255),
                                    size: 40,
                                  ),
                                  //space
                                  SizedBox(
                                    height: 10,
                                  ),
                                  Text(
                                    "設定新裝置",
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 255, 255, 255)),
                                  ),
                                ],
                              )),
                            ),
                          ),
                          //加入既有裝置
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                      transitionDuration: const Duration(milliseconds: 200),
                                      pageBuilder: (context, animation, secondaryAnimation) {
                                        return SlideTransition(
                                          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(animation),
                                          child: const AddDevice(),
                                        );
                                      }));
                            },
                            child: Container(
                              height: MediaQuery.of(context).size.height * 0.2,
                              width: MediaQuery.of(context).size.width * 0.6,
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 133, 154, 153),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(
                                  child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add,
                                    color: Color.fromARGB(255, 255, 255, 255),
                                    size: 40,
                                  ),
                                  //space
                                  SizedBox(
                                    height: 10,
                                  ),
                                  Text(
                                    "加入既有裝置",
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 255, 255, 255)),
                                  ),
                                ],
                              )),
                            ),
                          ),
                        ],
                      )),
                ],
              ))),
    );
  }
}
