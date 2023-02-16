
import 'package:flutter/services.dart';

class FlutterModule{
  // 静态注册 一个 channel （需要原生来匹配，匹配后，_channel 就可以通过该通道执行一些函数了）
  static const MethodChannel _channel = MethodChannel('flutter_channel');
  // 静态注册一个 方法
  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
  static Future<void> jump2FlutterViewPage()async {
    await _channel.invokeMethod("jump2FlutterViewPage");
  }
}