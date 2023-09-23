import 'package:flutter_line_sdk/flutter_line_sdk.dart';
import 'package:smart_plug_control/httpreq.dart';

// ignore: camel_case_types
class lineLogin {
  lineLogin() {
    initLineSDK();
  }

  Future<void> initLineSDK() async {
    await LineSDK.instance.setup("2000422286").then((_) {});
  }

  Future<dynamic> connectToLine(Device device) async {
    try {
      final result = await LineSDK.instance.login(
        option: LoginOption(false, "aggressive"),
        scopes: ["profile", "openid", "message.write"],
      );

      if (result.userProfile == null) {
        return false;
      }

      final profile = await LineSDK.instance.getProfile();
      final mid = profile.userId;

      line_account theAccount = line_account(mid: mid, name: profile.displayName, pictureUrl: profile.pictureUrl ?? "", statusMessage: profile.statusMessage ?? "");

      HttpReq()
          .regLine(
            theAccount,
            device,
          )
          .then((value) => {
                // print(value)
              });
      return true;
    } catch (e) {
      return false;
    }
  }
}
