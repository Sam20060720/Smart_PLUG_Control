import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:smart_plug_control/intro.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_plug_control/home.dart';
import 'package:smart_plug_control/httpreq.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Than we setup preferred orientations,
  // and only after it finished we run our app
  //SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((value) => runApp(const MyApp()));
  // final data = MediaQueryData.fromView(WidgetsBinding.instance.window);

  // is is tablet or phone
  //status bar color

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((value) {
    // bool isTablet = data.size.shortestSide >= 600;
    //reset device list
    // SharedPreferences.getInstance().then((dynamic value) => value.setStringList('devices', [] as List<String>));

    try {
      List<Device> devices = [];
      SharedPreferences.getInstance().then((SharedPreferences sharedPreference) {
        List<String> listString = sharedPreference.getStringList('devices') ?? [];
        devices = listString.map((item) => Device.fromJson(json.decode(item))).toList();
        if (devices.isNotEmpty) {
          runApp(const MyApp());
        } else {
          runApp(const MyAppIntro());
        }
      });
    } catch (e) {
      runApp(const MyAppIntro());
    }
  });
}

class MyAppIntro extends StatelessWidget {
  const MyAppIntro({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
      statusBarBrightness: Brightness.light,
    ));
    return MaterialApp(
      navigatorObservers: [FlutterSmartDialog.observer],
      builder: FlutterSmartDialog.init(),
      theme: ThemeData(
        // useMaterial3: true,
        buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
        primarySwatch: Colors.blue,
      ),
      home: const IntroPage(),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
      statusBarBrightness: Brightness.light,
    ));
    return MaterialApp(
      navigatorObservers: [FlutterSmartDialog.observer],
      builder: FlutterSmartDialog.init(),
      theme: ThemeData(
        // useMaterial3: true,
        buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}
