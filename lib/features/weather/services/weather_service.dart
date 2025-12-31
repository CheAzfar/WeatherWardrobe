import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/weather_info.dart';

class WeatherService {
  // Your OpenWeather API key
  static const String apiKey = 'e239bf6c2fea38cf84dd02f2bde6c18f';

  static Future<WeatherInfo> fetchByCity(String city) async {
    final uri = Uri.https(
      'api.openweathermap.org',
      '/data/2.5/weather',
      {
        'q': city,
        'appid': apiKey,
        'units': 'metric',
      },
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'Weather API error ${response.statusCode}: ${response.body}',
      );
    }

    final data = jsonDecode(response.body);

    final double tempC = (data['main']['temp'] as num).toDouble();
    final int humidity = (data['main']['humidity'] as num).toInt();
    final double windMs =
        ((data['wind']?['speed'] ?? 0) as num).toDouble();
    final double windKmh = windMs * 3.6;

    final String condition =
        (data['weather'][0]['main'] ?? 'Unknown').toString();

    final String conditionLower = condition.toLowerCase();
    final bool isRaining =
        conditionLower.contains('rain') ||
        conditionLower.contains('drizzle') ||
        conditionLower.contains('thunderstorm') ||
        data['rain'] != null;

    final String cityName = (data['name'] ?? city).toString();

    return WeatherInfo(
      tempC: tempC,
      condition: condition,
      humidity: humidity,
      windKmh: windKmh,
      isRaining: isRaining,
      city: cityName,
    );
  }
}
