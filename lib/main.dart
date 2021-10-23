import 'package:flutter/material.dart';
import 'package:english_words/english_words.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:gpt_3_dart/gpt_3_dart.dart';

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
  String _script = "no script";
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

    String description = wData.weather.description;
    String city = wData.name;
    String country = wData.country;
    String temp = wData.main.temp.toStringAsFixed(1);
    String tempMax = wData.main.tempMax.toStringAsFixed(1);
    String tempMin = wData.main.tempMin.toStringAsFixed(1);
    DateTime now = DateTime.now();
    String month = now.month.toString();
    String day = now.day.toString();

    String prompt = "This is the weather forecast for ${city} City, ${country}. The weather for today, ${month}/${day}, is forecast to be ${description}, with a current temperature of ${temp} degrees Celsius, a high of ${tempMax} degrees Celsius, and a low of ${tempMin} degrees Celsius. A polite announcer will explains this to us.\nAnnouncer:";
    print(prompt);
    getGpt3Response(prompt);
  }

  getGpt3Response(String prompt) async{
    OpenAI openAI = new OpenAI(apiKey: "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");
    String complete = await openAI.complete(prompt, 100, temperature: 0.75, n: 10);
    setState(() {
      _script = complete;
    });
  }

  pushButton(){
    getLocation();
  }

  @override
  Widget build(BuildContext context){
    final double deviceHeight = MediaQuery.of(context).size.height;
    final double deviceWidth = MediaQuery.of(context).size.width;
    final double fontSize = 18;
    final TextStyle style = TextStyle(fontSize: fontSize);

    return Scaffold(
      backgroundColor: Colors.cyan.shade50,
      appBar: AppBar(
        backgroundColor: Colors.cyan,
        centerTitle: true,
        title: Text('Otenki One-San'),
      ),
      body: Center(
        child: Column(
          children: [
            Container(
              height: 15,
            ),
            SizedBox(
              width: deviceWidth * 0.9,
              child: Card(
                color: Colors.cyan.shade100,
                elevation: 20,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  child: Column(
                    children: <Widget>[
                      Text(_location, style: style),
                      Text(_gotWeather ? wData.main.temp.toStringAsFixed(1) : "no data", style: style),
                      Text(_gotWeather ? wData.weather.description : "no data", style: style),
                      Text(_gotWeather ? wData.name : "no data", style: style),
                      Text(_gotWeather ? wData.country : "no data", style: style),
                    ],
                  ),
                ),
              ),
            ),
            Text(_script),
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
