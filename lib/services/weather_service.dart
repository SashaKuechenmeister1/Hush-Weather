import 'dart:convert';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import 'package:http/http.dart' as http;



class WeatherService {

  final String apiKey;

  WeatherService(this.apiKey);

  Future<Map<String, dynamic>> getWeather(String cityName, [String units = 'metric']) async {
    final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?q=$cityName&appid=$apiKey&units=$units');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body); // Return the raw JSON response
    } else {
      throw Exception('Failed to fetch weather data: ${response.body}');
    }
  }


  Future<String> getCurrentCity() async {

    // Get permissions for location
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // Fetch the current location
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high);

    // convert location into a list of placemark objects
    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude, position.longitude); 

    // extract the city name from the first placemark
    String? city = placemarks[0].locality;

    return city ?? 'Unknown location';
  }


}