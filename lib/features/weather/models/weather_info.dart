class WeatherInfo {
  final double tempC;
  final String condition;
  final int humidity;
  final double windKmh;
  final bool isRaining;
  final String city;

  WeatherInfo({
    required this.tempC,
    required this.condition,
    required this.humidity,
    required this.windKmh,
    required this.isRaining,
    required this.city,
  });
}
