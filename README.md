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


### 以FlutterView 方式在原生中嵌入 Flutter 页面 
## 原生
~~~
    class FlutterViewActivity :AppCompatActivity() { //常规Activity 
    lateinit var flutterEngine :FlutterEngine 
    lateinit var flutterView:FlutterView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        init()  // 初始化 engine 与 FlutterView 
        setContentView(flutterView)  // 设置FlutterView 到 layout ，也可以将FlutterView 添加到某个View 上
        bindEngineLife() // 绑定engine的生命周期
    
    }
    private fun bindEngineLife() { 
       lifecycle.addObserver(object:DefaultLifecycleObserver{
            override fun onStart(owner: LifecycleOwner) {
                super.onStart(owner)
                flutterEngine.lifecycleChannel.appIsResumed()
            }

            override fun onStop(owner: LifecycleOwner) {
                super.onStop(owner)
                flutterEngine.lifecycleChannel.appIsInactive()
            }

            override fun onDestroy(owner: LifecycleOwner) {
                super.onDestroy(owner)
                flutterEngine.lifecycleChannel.appIsDetached()
                flutterEngine.destroy()
            }
        })
    }

    private fun init() {
        flutterView = FlutterView(this)
        flutterEngine = FlutterEngine(this)
        flutterEngine.navigationChannel.setInitialRoute("/second")
        flutterEngine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault()
        );
        flutterView.attachToFlutterEngine(flutterEngine) // FlutterView 需要 FLutter Engine驱动
        // 通讯渠道设置
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger,"flutter_channel").setMethodCallHandler(object:MethodChannel.MethodCallHandler{
            override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
                   when(call.method){
                       "getPlatformVersion" -> {
                           result.success("android ${Build.VERSION.SDK_INT}")
                       }
                       "jump2FlutterViewPage" -> {
                           startActivity(Intent(this@FlutterViewActivity,FlutterViewActivity::class.java))
                       }
                       else -> {
                           result.notImplemented()
                       }
                   }
            }
        })
        
        nativeChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger,"native_channel") // 可以通过 nativeChannel 主动发消息给 Flutter 
    }
    
     lateinit var nativeChannel: MethodChannel

}
~~~    
## dart 
~~~
  dart 中没有特别之处，主要就是 通信channel 的建立
  
  // flutter 调用 native
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
    
  //调用 函数1
  var platformVersion = await FlutterModule.platformVersion;
  // 函数2 
  await FlutterModule.jump2FlutterViewPager();
     


  // 在页面 initState 时 初始化 channel ，以及在特定时机调用 原生channel 
  
  // native_channel 接收
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

~~~

### 原生 嵌入FlutterFragment 并双工通信
## 原生
~~~
    // App 提前准备 FlutterEngine （防止直接createEngine 拿不到，并且可以设置路由）
      var flutterEngine = FlutterEngine(this)
        flutterEngine.navigationChannel.setInitialRoute("/third")
        flutterEngine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault()
        )
       FlutterEngineCache.getInstance().put("/third",flutterEngine)
    
    // Activity 中 创建并添加 FlutterFragment    
    
     var flutterFragment = FlutterFragment.withCachedEngine("/third").build<FlutterFragment>()
        supportFragmentManager.beginTransaction()
            .replace(R.id.fl,flutterFragment)
            .commit()
        
        var engine = FlutterEngineCache.getInstance().get("/third")
        //初始化通道
        MethodChannel(engine?.dartExecutor?.binaryMessenger,"flutter_to_native").setMethodCallHandler(object:MethodChannel.MethodCallHandler{
            override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
                if(call.method == "flutterSend"){
                    findViewById<TextView>(R.id.tv_content).append(call.arguments.toString())
                }
            }
        })

        nativeChannel = MethodChannel(engine?.dartExecutor?.binaryMessenger,"native_to_flutter")

        // 生命周期绑定
        lifecycle.addObserver(object :DefaultLifecycleObserver{
            override fun onStart(owner: LifecycleOwner) {
                super.onStart(owner)
                flutterFragment.onStart()
            }

            override fun onStop(owner: LifecycleOwner) {
                super.onStop(owner)
                flutterFragment.onStop()
            }

            override fun onDestroy(owner: LifecycleOwner) {
                super.onDestroy(owner)
                flutterFragment.onDestroy()
            }
        })
    }
    
    // 原生调用Flutter
     nativeChannel.invokeMethod("nativeSend",content)
~~~
## dart
~~~
    // 在对应 router 组件下 创建通道
    
  MethodChannel methodChannel = MethodChannel("flutter_to_native");
  String _content  = "";
  @override
  void initState() {
    super.initState();
    methodChannel.setMethodCallHandler(_methodCallHandler);
  }

  Future<dynamic> _methodCallHandler(MethodCall call) async{
      if(call.method == "nativeSend"){
          _content = _content +"\n";
          _content =_content + call.arguments.toString();
          setState(() {

          });
      }
  }
    
    
 // 独立的一个 channel 类中 
 
 import 'package:flutter/services.dart';

class FlutterModule{
  // 静态注册 一个 channel （需要原生来匹配，匹配后，_channel 就可以通过该通道执行一些函数了）
  static const MethodChannel _channel = MethodChannel('flutter_to_native');
  // 静态注册一个 方法
  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
  static Future<void> jump2FlutterViewPage()async {
    await _channel.invokeMethod("jump2FlutterViewPage");
  }

  static Future<void> jump2FlutterFragmentActivity() async{
    await _channel.invokeMethod("jump2FlutterFragmentActivity");
  }

  static Future<void> flutterSend(String msg) async {
    await _channel.invokeMethod("flutterSend",msg);
}
}
   
  // 在需要的位置 调用特定的channel ， 需要注意这里声明了两个 channel 
  // 通知 原生 还是使用 FlutterModule ，接收原生 消息 在 flutter_to_native 的channel 回调中
    FlutterModule.flutterSend(textEditController.text.toString());
~~~


### 单独打包 module 为 aar ，native 无需集成Flutter 环境

~~~
 cd .android 
 ./gradlew flutter:assembleDebug
 
 出错
 Execution failed for task ':flutter:compileDebugJavaWithJavac'.
> Could not find tools.jar. Please check that /Library/Internet Plug-Ins/JavaAppletPlugin.plugin/Contents/Home contains a valid JDK installation.

 .android/gradle.properties 添加本地JDK配置
 org.gradle.java.home=/Applications/Android Studio.app/Contents/jre/Contents/Home
 再次打包  
 解决  .android/Flutter/build/outputs/aar/flutter-debug.aar
~~~

