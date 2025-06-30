
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class WeatherService {
  final String apiKey = '14969c9f15f763dd598afde0fb1ce331';
  Stream<Map<String, dynamic>> getWeatherStream() async* {
    while (true) {
      final weather = await fetchWeatherFromLocation();
      if (weather != null) {
        yield weather;
      }
      await Future.delayed(const Duration(minutes: 15));
    }
  }

  Future<Map<String, dynamic>?> fetchWeatherFromLocation() async {
    try {
      // 1. Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      // 2. Get current position
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      double lat = position.latitude;
      double lon = position.longitude;

      // 3. Use coordinates to get weather
      final url =
          'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'temp': data['main']['temp'],
          'description': data['weather'][0]['description'],
          'icon': data['weather'][0]['icon'],
          'location': data['name'],
        };
      } else {
        print("Weather API status: ${response.statusCode}");
        print("Weather API response: ${response.body}");
      }
    } catch (e) {
      print("Error fetching weather: $e");
    }
    return null;
  }
}

