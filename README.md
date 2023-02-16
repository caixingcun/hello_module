# hello_module

A new flutter module project.

## Getting Started

For help getting started with Flutter, view our online
[documentation](https://flutter.dev/).

For instructions integrating Flutter modules to your existing applications,
see the [add-to-app documentation](https://flutter.dev/docs/development/add-to-app).


### Flutter 与原生通信 MethodChannel （一进入首页 就进Flutter，原生负责基础能力，Flutter进行通信）
## 原生
~~~
 class MainActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        Log.d("tag","configureFlutterEngine")
        var channel =   MethodChannel(flutterEngine.dartExecutor.binaryMessenger,"flutter_channel")
        channel.setMethodCallHandler { call, result ->
            // flutter 调原生
            if(call.method == "getPlatformVersion"){
                // 原生回复flutter
                result.success("android ${Build.VERSION.SDK_INT}")
            }else {
                result.notImplemented()
            }
        }
    }

}
~~~
## dart
~~~
import 'package:flutter/services.dart';

class FlutterModule{
  // 静态注册 一个 channel （需要原生来匹配，匹配后，_channel 就可以通过该通道执行一些函数了）
  static const MethodChannel _channel = MethodChannel('flutter_channel');
  // 静态注册一个 方法
  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}

// 使用
var _platformVersion = await FlutterModule.platformVersion
~~~


### 混合开发 开屏flutter 页面下  原生通知Flutter

## 原生
~~~
class MainActivity : FlutterActivity() {

    lateinit var nativeChannel: MethodChannel
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        nativeChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger,"native_channel")
         // 原生主动回复 flutter
        nativeChannel.invokeMethod("flutter_print","i am native")
    }

}
~~~

## dart 
~~~
  static MethodChannel native_channel = const MethodChannel("native_channel");
  
  void initNativeChannel(){
    native_channel.setMethodCallHandler(_nativeMethodChannelCallHandler);
  }

  Future<dynamic> _nativeMethodChannelCallHandler(MethodCall call) async{
    switch(call.method){
      case 'flutter_print':
        print("${call.arguments}");
        break;
    }
  }
  
  @override
  void initState() {
    initNativeChannel(); // 提前注册
    super.initState();
  }

~~~

