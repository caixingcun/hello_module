
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hello_module/channels.dart';

class ThirdPage extends StatefulWidget {
  @override
  _ThirdPageState createState() => _ThirdPageState();
}


class _ThirdPageState extends State<ThirdPage> {
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

  var textEditController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    textEditController.addListener(() {

    });

      return Scaffold(
        body: Center(
          child: Column(
            children: [
              TextField(controller: textEditController),
              FlatButton(onPressed: (){
                FlutterModule.flutterSend(textEditController.text.toString());
              }, child: Text("发送Flutter内容")),
              Text("$_content"),
            ],
          ),
        ),
      );
  }
}