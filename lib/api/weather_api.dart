import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:weather/weather.dart';

class WeatherApi {
  String cityName = "Rosenheim";
  final url =
      Uri.parse('https://api.inf.th-rosenheim.de/api/ai/chat/completions');

  WeatherFactory wf = WeatherFactory("9fb8dcd3561cffb98e568311e7bbe662",
      language: Language.GERMAN);

  Future<Weather> getWeather() {
    return wf.currentWeatherByCityName(cityName);
  }

  Future<String> getSuggestion() async {
    Weather weather = await getWeather();

    String contentString =
        "Hier ist eine aktuelle Wettermeldung: ${weather.weatherDescription}, Max: ${weather.tempMax}, Min: ${weather.tempMin}. Bitte sag mir was ich anziehen soll. Die Antwort soll so aussehen: Oben: Pullover/T-Shirt, Unten: Kurze Hose/Lange Hose";

    final Map<String, dynamic> requestBody = {
      "model_name": "gpt-4o",
      "temperature": 1,
      "top_p": 0,
      "presence_penalty": 0.2,
      "frequency_penalty": 0.5,
      "max_tokens": 0,
      "stop": ["string"],
      "messages": [
        {"role": "user", "content": contentString}
      ]
    };

    final response = await http.post(url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "" //Bearer Token hier einfügen
        },
        body: jsonEncode(requestBody));

    final responseBody = jsonDecode(response.body);
    final content = responseBody['choices'][0]['message']['content'];
    return content;
  }
}
