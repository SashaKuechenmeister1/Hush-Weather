class Weather {
  final String cityName;
  final String country;
  final double temperature;
  final double feelsLike;
  final double tempMin;
  final double tempMax;
  final int humidity;
  final double windSpeed;
  final int visibility;
  final String mainCondition;

  Weather({
    required this.cityName,
    required this.country,
    required this.temperature,
    required this.feelsLike,
    required this.tempMin,
    required this.tempMax,
    required this.humidity,
    required this.windSpeed,
    required this.visibility,
    required this.mainCondition,
  });

  // Factory constructor to create a Weather object from the API response
  factory Weather.fromApi(Map<String, dynamic> json) {
    return Weather(
      cityName: json['name'] as String? ?? 'Unknown City',
      country: (json['sys'] != null && json['sys']['country'] != null)
          ? json['sys']['country'] as String
          : 'Unknown Country',
      temperature: (json['main'] != null && json['main']['temp'] != null)
          ? (json['main']['temp'] as num).toDouble()
          : 0.0,
      feelsLike: (json['main'] != null && json['main']['feels_like'] != null)
          ? (json['main']['feels_like'] as num).toDouble()
          : 0.0,
      tempMin: (json['main'] != null && json['main']['temp_min'] != null)
          ? (json['main']['temp_min'] as num).toDouble()
          : 0.0,
      tempMax: (json['main'] != null && json['main']['temp_max'] != null)
          ? (json['main']['temp_max'] as num).toDouble()
          : 0.0,
      humidity: (json['main'] != null && json['main']['humidity'] != null)
          ? json['main']['humidity'] as int
          : 0,
      windSpeed: (json['wind'] != null && json['wind']['speed'] != null)
          ? (json['wind']['speed'] as num).toDouble()
          : 0.0,
      visibility: json['visibility'] as int? ?? 0,
      mainCondition: (json['weather'] != null && json['weather'].isNotEmpty)
          ? json['weather'][0]['main'] as String
          : 'Unknown',
    );
  }

  // Factory constructor to create a Weather object from saved bookmarks
  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      cityName: json['cityName'] as String,
      country: json['country'] as String,
      temperature: (json['temperature'] as num).toDouble(),
      feelsLike: (json['feelsLike'] as num).toDouble(),
      tempMin: (json['tempMin'] as num).toDouble(),
      tempMax: (json['tempMax'] as num).toDouble(),
      humidity: json['humidity'] as int,
      windSpeed: (json['windSpeed'] as num).toDouble(),
      visibility: json['visibility'] as int,
      mainCondition: json['mainCondition'] as String,
    );
  }

  // Method to convert a Weather object to JSON for saving bookmarks
  Map<String, dynamic> toJson() {
    return {
      'cityName': cityName,
      'country': country,
      'temperature': temperature,
      'feelsLike': feelsLike,
      'tempMin': tempMin,
      'tempMax': tempMax,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'visibility': visibility,
      'mainCondition': mainCondition,
    };
  }
}
