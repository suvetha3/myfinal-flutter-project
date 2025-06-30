import 'package:flutter/material.dart';
import '../services/weather_service.dart';

class WeatherCard extends StatelessWidget {
  const WeatherCard({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: WeatherService().getWeatherStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(10),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(10),
            child: Center(child: Text('Unable to fetch weather')),
          );
        }

        final weather = snapshot.data!;
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          child: ListTile(
            leading: Image.network(
              'https://openweathermap.org/img/wn/${weather['icon']}@2x.png',
              width: 50,
              height: 50,
            ),
            title: Text('Temp: ${weather['temp']}°C - ${weather['location']}'),
            subtitle: Text('${weather['description']}'.toUpperCase()),
          ),
        );
      },
    );
  }
}
