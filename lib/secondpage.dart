

import 'package:flutter/material.dart';

import 'channels.dart';

class SecondPage extends StatefulWidget {

   @override
   _SecondPageState createState() => _SecondPageState();

}

class _SecondPageState extends State<SecondPage> {
  String? _platform = "未初始化";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _getVersion();
  }
  @override
  Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(title: Text("second page"),),
        body: Center(
          child:  Text("$_platform"),
        ),
        floatingActionButton: FloatingActionButton(
          child: Text("开新页面"),
          onPressed: (){
            FlutterModule.jump2FlutterViewPage();
          },
        ),
      );
  }

  _getVersion() async {
    _platform = await FlutterModule.platformVersion;
    setState(() {
    });
  }
}
