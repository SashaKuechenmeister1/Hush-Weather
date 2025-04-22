bool isDayTime() {
  final now = DateTime.now();
  return now.hour >= 6 && now.hour < 18;
}

String getFriendlyCondition(String condition) {
  switch (condition) {
    case 'Clouds':
      return 'Cloudy';
    case 'Rain':
      return 'Rainy';
    case 'Drizzle':
      return 'Drizzling';
    case 'Thunderstorm':
      return 'Stormy';
    case 'Snow':
      return 'Snowy';
    case 'Mist':
    case 'Fog':
    case 'Haze':
      return 'Foggy';
    default:
      return condition;
  }
}