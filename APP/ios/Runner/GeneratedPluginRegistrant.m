//
//  Generated file. Do not edit.
//

// clang-format off

#import "GeneratedPluginRegistrant.h"

#if __has_include(<flutter_ble_lib_ios_15/FlutterBleLibPlugin.h>)
#import <flutter_ble_lib_ios_15/FlutterBleLibPlugin.h>
#else
@import flutter_ble_lib_ios_15;
#endif

#if __has_include(<flutter_line_sdk/FlutterLineSdkPlugin.h>)
#import <flutter_line_sdk/FlutterLineSdkPlugin.h>
#else
@import flutter_line_sdk;
#endif

#if __has_include(<flutter_native_splash/FlutterNativeSplashPlugin.h>)
#import <flutter_native_splash/FlutterNativeSplashPlugin.h>
#else
@import flutter_native_splash;
#endif

#if __has_include(<network_info_plus/FLTNetworkInfoPlusPlugin.h>)
#import <network_info_plus/FLTNetworkInfoPlusPlugin.h>
#else
@import network_info_plus;
#endif

#if __has_include(<permission_handler_apple/PermissionHandlerPlugin.h>)
#import <permission_handler_apple/PermissionHandlerPlugin.h>
#else
@import permission_handler_apple;
#endif

#if __has_include(<sensors_plus/FLTSensorsPlusPlugin.h>)
#import <sensors_plus/FLTSensorsPlusPlugin.h>
#else
@import sensors_plus;
#endif

#if __has_include(<shared_preferences_foundation/SharedPreferencesPlugin.h>)
#import <shared_preferences_foundation/SharedPreferencesPlugin.h>
#else
@import shared_preferences_foundation;
#endif

#if __has_include(<uni_links/UniLinksPlugin.h>)
#import <uni_links/UniLinksPlugin.h>
#else
@import uni_links;
#endif

#if __has_include(<url_launcher_ios/FLTURLLauncherPlugin.h>)
#import <url_launcher_ios/FLTURLLauncherPlugin.h>
#else
@import url_launcher_ios;
#endif

@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
  [FlutterBleLibPlugin registerWithRegistrar:[registry registrarForPlugin:@"FlutterBleLibPlugin"]];
  [FlutterLineSdkPlugin registerWithRegistrar:[registry registrarForPlugin:@"FlutterLineSdkPlugin"]];
  [FlutterNativeSplashPlugin registerWithRegistrar:[registry registrarForPlugin:@"FlutterNativeSplashPlugin"]];
  [FLTNetworkInfoPlusPlugin registerWithRegistrar:[registry registrarForPlugin:@"FLTNetworkInfoPlusPlugin"]];
  [PermissionHandlerPlugin registerWithRegistrar:[registry registrarForPlugin:@"PermissionHandlerPlugin"]];
  [FLTSensorsPlusPlugin registerWithRegistrar:[registry registrarForPlugin:@"FLTSensorsPlusPlugin"]];
  [SharedPreferencesPlugin registerWithRegistrar:[registry registrarForPlugin:@"SharedPreferencesPlugin"]];
  [UniLinksPlugin registerWithRegistrar:[registry registrarForPlugin:@"UniLinksPlugin"]];
  [FLTURLLauncherPlugin registerWithRegistrar:[registry registrarForPlugin:@"FLTURLLauncherPlugin"]];
}

@end
