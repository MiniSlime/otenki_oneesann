import 'package:flutter/material.dart';
import 'package:english_words/english_words.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

var serverURL = "https://api.openweathermap.org/data/2.5/find?";
var apiKey = "f797e7d91765dd336ae257abd4338dd0";

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
  String _latitude = "";
  String _longitude = "";
  bool _gotWeather = false;
  WeatherData wData;

  Future<void> getLocation() async{
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy:  LocationAccuracy.high);
    setState(() {
      _location = position.toString();
      _latitude = position.latitude.toString();
      _longitude = position.longitude.toString();
    });
    String url=serverURL + "lat=" + _latitude + "&lon=" + _longitude + "&appid=" + apiKey + "&cnt=1&lang=en";
    getWeather(url);
  }

  getWeather(String url) async{
    Uri _uri = Uri.parse(url);
    final response = await http.get(_uri);
    Map<String, dynamic> info = json.decode(utf8.decode(response.bodyBytes));
    ApiData data = ApiData.fromJson(info);
    setState(() {
      wData = data.data;
      _gotWeather = true;
    });
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
        child: Column(
          children: <Widget>[
            Text(_location),
            Text(_gotWeather ? wData.weather.description : "no data"),
            Text(_gotWeather ? wData.name : "no data"),
            Text(_gotWeather ? wData.country : "no data"),
          ],
        ),
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

class ApiData {
  final String message;
  final int cod;
  final WeatherData data;

  ApiData(this.message, this.cod, this.data);

  ApiData.fromJson(Map<String, dynamic> json)
      :
        message = json['message'].toString(),
        cod = int.parse(json['cod']),
        data = WeatherData.fromJson(json['list'][0]);
}

class WeatherData{
  final String id;
  final String name;
  final Coord coord;
  final MainWeatherData main;
  final int dt;
  final Weather weather;
  final String country;

  WeatherData(this.id, this.name, this.coord, this.main, this.dt, this.weather, this.country);

  WeatherData.fromJson(Map<String, dynamic> json)
      :
        id = json['id'].toString(),
        name = json['name'].toString(),
        coord = Coord.fromJson(json),
        main = MainWeatherData.fromJson(json),
        dt = json['dt'],
        country = json['sys']['country'],
        weather = Weather.fromJson(json);

}

class MainWeatherData{

  MainWeatherData(this.temp, this.feelsLike, this.tempMax, this.tempMin, this.pressure, this.humidity, this.seaLevel, this.grndLevel);

  MainWeatherData.fromJson(Map<String, dynamic> json)
      :
        temp = json['main']["temp"] - 273 ?? -9999,
        tempMin = json['main']["temp_min"] - 273 ?? -9999,
        tempMax = json['main']["temp_max"]- 273 ?? -9999,
        feelsLike = json['main']["feels_like"] - 273 ?? -9999,
        pressure = json['main']["pressure"] ?? -9999,
        humidity = json['main']["humidity"] ?? -9999,
        seaLevel = json['main']["sea_level"] ?? -9999,
        grndLevel = json['main']["grnd_level"] ?? -9999;


  final double temp;
  final double feelsLike;
  final double tempMin;
  final double tempMax;
  final int pressure;
  final int humidity;
  final int seaLevel;
  final int grndLevel;
}

class Weather {

  final int id;
  final String main;
  final String description;
  final String icon;

  Weather(this.main, this.description, this.icon, this.id);

  Weather.fromJson(Map<String, dynamic> json)
      :
        id = json['weather'][0]['id'],
        main = json['weather'][0]['main'],
        description = json['weather'][0]['description'],
        icon = json['weather'][0]['icon'];
}

class Coord{
  final double lat;
  final double lon;

  Coord(this.lat, this.lon);

  Coord.fromJson(Map<String, dynamic> json)
      :
        lat = json['coord']['lat'],
        lon = json['coord']['lon'];
}
