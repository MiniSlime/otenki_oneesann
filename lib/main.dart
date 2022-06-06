import 'package:flutter/material.dart';
// import 'package:english_words/english_words.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:gpt_3_dart/gpt_3_dart.dart';
import 'dart:convert' as convert;

var serverURL = "https://api.openweathermap.org/data/2.5/find?";
var apiKeyWeather = "secret";
var apiKeyGPT3 = "secret";

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
    String url = serverURL + "lat=" + _latitude + "&lon=" + _longitude + "&appid=" + apiKeyWeather + "&cnt=1&lang=en";
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

    String url2 = "https://api.openweathermap.org/data/2.5/onecall?lat=${_latitude}&lon=${_longitude}&exclude=current,minutely,daily,alerts&units=metric&appid=$apiKeyWeather";
    Uri _uri2 = Uri.parse(url2);
    final response2 = await http.get(_uri2);
    Map<String, dynamic> res;
    if(response2.statusCode == 200){
      var jsonResponse =
          convert.jsonDecode(response2.body) as Map<String, dynamic>;
      res = jsonResponse;
    }else{
      print('Request failed with status: ${response2.statusCode}.');
    }

    List<String> futureWeather = [];
    for(int i=0;i<24;i++){
      Map<String, dynamic> forecast = res['hourly'][i];
      String forecastPrompt = "${i + 1}hour(s) later, ";
      forecastPrompt += "weather is ${forecast['weather'][0]['main']}, \n";
      forecastPrompt += "temperature is ${forecast['temp']} degrees Celsius, ";
      forecastPrompt += "humidity is ${forecast['humidity']}%, ";
      forecastPrompt += "wind speed is ${forecast['wind_speed']}m/s.\n";

      futureWeather.add(forecastPrompt);
    }

    String description = wData.weather.description;
    String city = wData.name;
    String country = wData.country;
    String temp = wData.main.temp.toStringAsFixed(1);
    String tempMax = wData.main.tempMax.toStringAsFixed(1);
    String tempMin = wData.main.tempMin.toStringAsFixed(1);
    DateTime now = DateTime.now();
    String month = now.month.toString();
    String day = now.day.toString();
    String hour = now.hour.toString();
    String minute = now.minute.toString();

    String prompt = "Information: Here is the weather forecast for ${city} City, ${country} at ${hour}:${minute} on ${month}/${day}. Today's weather is ${description}, with a current temperature of ${temp} degrees Celsius, a high of ${tempMax} degrees Celsius, and a low of ${tempMin} degrees Celsius.\n";
    prompt += "\nIn addition, the forecast for weather, temperature, humidity and wind speed for the next 24 hours is as follows\n\n";

    for(int i=3;i<24;i+=4){
      prompt += futureWeather[i];
    }

    prompt += "\nBased on this information, a cheerful announcer will give you a weather forecast.\n\nAnnouncer:";
    setState(() {
      _script = prompt;
    });
    print(prompt);
    getGpt3Response(prompt);
  }

  getGpt3Response(String prompt) async{
    OpenAI openAI = new OpenAI(apiKey: apiKeyGPT3);
    String complete = await openAI.complete(prompt, 100, temperature: 0.8);
    setState(() {
      _script = complete;
    });

    translation(_script);
  }

  translation(String script) async{
    String url = "https://script.google.com/macros/s/AKfycbzeAEgBUSKw2jwwG4SBdWI50xBlscJO80KVQKc7axxd5EzsLnI/exec?text=" + script + "&source=en&target=ja";
    Uri _uri = Uri.parse(url);
    var response = await http.get(_uri);
    if(response.statusCode == 200){
      var jsonResponse = convert.jsonDecode(response.body) as Map<String, dynamic>;
      String text = jsonResponse['text'];
      setState(() {
        _script = text;
      });
    }else{
      setState(() {
        _script = "翻訳エラーが発生しました";
      });
    }
  }

  pushButton(){
    getLocation();
  }

  @override
  Widget build(BuildContext context){
    // final double deviceHeight = MediaQuery.of(context).size.height;
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
                      Text("Temp：" + (_gotWeather ? wData.main.temp.toStringAsFixed(1) : "no data"), style: style),
                      Text("TempMax：" + (_gotWeather ? wData.main.tempMax.toStringAsFixed(1) : "no data"), style: style),
                      Text("TempMin：" + (_gotWeather ? wData.main.tempMin.toStringAsFixed(1) : "no data"), style: style),
                      Text("Weather：" + (_gotWeather ? wData.weather.description : "no data"), style: style),
                      Text("Location：" + (_gotWeather ? wData.name + ", " + wData.country : "no data"), style: style),
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
