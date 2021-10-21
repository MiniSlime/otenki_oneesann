import 'package:flutter/material.dart';
import 'package:english_words/english_words.dart';
import 'package:geolocator/geolocator.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget{
  @override
  Widget build(BuildContext context){
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Otenki One-San',
      home: Otenki(),
    );
  }
}

class OtenkiState extends State<Otenki>{
  String _location = "no data";
  Future<void> getLocation() async{
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy:  LocationAccuracy.high);
    print("緯度: " + position.latitude.toString());
    print("経度: " + position.longitude.toString());
    print("高度: " + position.altitude.toString());
  }

  pushButton(){
    getLocation();
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.cyan,
        centerTitle: true,
        title: Text('Otenki One-San'),
      ),
      body: Center(

      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.cloud),
        onPressed: pushButton,
        backgroundColor: Colors.cyan,
      ),
    );
  }
}

class Otenki extends StatefulWidget{
  @override
  OtenkiState createState() => new OtenkiState();
}
