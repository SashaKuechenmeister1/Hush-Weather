import 'dart:convert'; // For jsonEncode and jsonDecode
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart'; // For SharedPreferences
import '../models/weather_model.dart';
import '../services/weather_service.dart';
import '../utils/weather_utils.dart';
import '../helpers/shared_preferences_helper.dart'; // Import SharedPreferencesHelper
import 'settings_page.dart'; // Import the SettingsPage

// Example color palette
const Color primaryTextColor = Colors.black;
const Color secondaryTextColor = Colors.black54;
const Color cardBackgroundColor = Colors.white;
const Color iconColor = Colors.black;

// Font styles
const TextStyle titleStyle = TextStyle(
  fontSize: 32,
  fontWeight: FontWeight.bold,
  color: primaryTextColor,
);

const TextStyle subtitleStyle = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.w400,
  color: secondaryTextColor,
);

const TextStyle bodyStyle = TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.w400,
  color: primaryTextColor,
);

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final TextEditingController _searchController = TextEditingController();
  final _weatherService = WeatherService('0ce37696e2c105f3f99a646fcb6f1021');
  Weather? _weather;
  final List<Weather> _bookmarks = [];
  bool _isLoading = false;
  String? _currentLocationCity; // Tracks the current location city
  bool _isMetric = true; // Default to Metric (Celsius)
  bool _isDarkMode = false; // Default to Light Mode

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadBookmarks();
    _fetchWeather();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isMetric = prefs.getBool('isMetric') ?? true;
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  Future<void> _loadBookmarks() async {
    final bookmarksJson = await SharedPreferencesHelper.getString(SharedPreferencesHelper.bookmarksKey);
    if (bookmarksJson != null) {
      setState(() {
        _bookmarks.addAll((jsonDecode(bookmarksJson) as List)
            .map((b) => Weather.fromJson(b))
            .toList());
      });
    }
  }

  Future<void> _saveBookmarks() async {
    final bookmarksJson = jsonEncode(_bookmarks.map((b) => b.toJson()).toList());
    await SharedPreferencesHelper.saveString(SharedPreferencesHelper.bookmarksKey, bookmarksJson);
  }

  Future<void> _fetchWeather() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String cityName = await _weatherService.getCurrentCity();
      final apiResponse = await _weatherService.getWeather(cityName, _isMetric ? 'metric' : 'imperial'); // Get raw JSON
      final weather = Weather.fromApi(apiResponse); // Parse JSON into Weather object

      setState(() {
        _weather = weather; // Update the main weather section
        _currentLocationCity = cityName; // Set the current location city
        _isLoading = false;

        // Add current location to bookmarks if not already present
        if (!_bookmarks.any((w) => w.cityName == weather.cityName)) {
          _bookmarks.insert(0, weather); // Add to the beginning of the list
          _saveBookmarks();
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error fetching weather data: $e"),
          duration: const Duration(seconds: 3),
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _searchWeather(String cityName) async {
    if (cityName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a city name."),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiResponse = await _weatherService.getWeather(cityName, _isMetric ? 'metric' : 'imperial'); // Get raw JSON
      final weather = Weather.fromApi(apiResponse); // Parse JSON into Weather object

      setState(() {
        _weather = weather; // Update the main weather section
        _isLoading = false;

        // Automatically add the searched city to bookmarks if not already present
        if (!_bookmarks.any((w) => w.cityName == weather.cityName)) {
          _bookmarks.add(weather);
          _saveBookmarks();
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error fetching weather data: $e"),
          duration: const Duration(seconds: 3),
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  void removeBookmark(String cityName) {
    setState(() {
      _bookmarks.removeWhere((w) => w.cityName == cityName);
      _saveBookmarks();

      // If the deleted city is the currently viewed city, fetch the current location's weather
      if (_weather != null && _weather!.cityName == cityName) {
        _fetchWeather(); // Fetch weather for the current location
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hush Weather"),
        backgroundColor: _isDarkMode ? Colors.black : Colors.grey[900],
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsPage(
                    isMetric: _isMetric,
                    isDarkMode: _isDarkMode,
                    onUnitChanged: (value) {
                      setState(() {
                        _isMetric = value;
                        _fetchWeather(); // Refresh weather data
                      });
                    },
                    onThemeChanged: (value) {
                      setState(() {
                        _isDarkMode = value;
                      });
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Container(
          color: _isDarkMode ? Colors.black : Colors.white,
          child: Stack(
            children: [
              // Main Content
              RefreshIndicator(
                onRefresh: _fetchWeather,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Search Bar
                        SearchBar(
                          controller: _searchController,
                          onSearch: () {
                            final cityName = _searchController.text.trim();
                            _searchWeather(cityName);
                          },
                          onOpenBookmarks: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (context) {
                                return _buildBookmarksList();
                              },
                            );
                          },
                          isDarkMode: _isDarkMode, // Pass dark mode state
                        ),
                        const SizedBox(height: 20),

                        // Main Weather Section
                        if (_weather != null)
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Column(
                              key: ValueKey(_weather),
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  "${_weather!.cityName}, ${_weather!.country}",
                                  style: titleStyle.copyWith(
                                    color: _isDarkMode ? Colors.white : Colors.black,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                Lottie.asset(
                                  getWeatherAnimation(_weather!.mainCondition),
                                  width: 160,
                                  height: 160,
                                ),
                                Text(
                                  "${_weather!.temperature.round()}°${_isMetric ? 'C' : 'F'}",
                                  style: TextStyle(
                                    fontSize: 50,
                                    fontWeight: FontWeight.bold,
                                    color: _isDarkMode ? Colors.white : Colors.black,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  getFriendlyCondition(_weather!.mainCondition),
                                  style: subtitleStyle.copyWith(
                                    color: _isDarkMode ? Colors.white70 : Colors.black54,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 25),

                        // Weather Details Section
                        if (_weather != null)
                          Wrap(
                            spacing: 12.0,
                            runSpacing: 12.0,
                            alignment: WrapAlignment.center,
                            children: [
                              _buildWeatherCard(Icons.thermostat, "Feels Like", "${_weather!.feelsLike.round()}°${_isMetric ? 'C' : 'F'}"),
                              _buildWeatherCard(Icons.water_drop, "Humidity", "${_weather!.humidity}%"),
                              _buildWeatherCard(Icons.arrow_downward, "Min Temp", "${_weather!.tempMin.round()}°${_isMetric ? 'C' : 'F'}"),
                              _buildWeatherCard(Icons.arrow_upward, "Max Temp", "${_weather!.tempMax.round()}°${_isMetric ? 'C' : 'F'}"),
                              _buildWeatherCard(Icons.visibility, "Visibility", "${(_weather!.visibility / 1000).toStringAsFixed(1)} km"),
                              _buildWeatherCard(Icons.air, "Wind Speed", "${_weather!.windSpeed} ${_isMetric ? 'm/s' : 'mph'}"),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // Loading Animation
              if (_isLoading)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build weather detail cards
  Widget _buildWeatherCard(IconData icon, String label, String value) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Card(
        color: _isDarkMode ? Colors.grey[900] : Colors.white, // Adjust card background for dark mode
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 2.0,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: _isDarkMode ? Colors.white : Colors.black, size: 20),
              const SizedBox(height: 6),
              Text(label, style: subtitleStyle.copyWith(fontSize: 14, color: _isDarkMode ? Colors.white : Colors.black), textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(value, style: bodyStyle.copyWith(fontSize: 16, color: _isDarkMode ? Colors.white : Colors.black), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build the bookmarks list
  Widget _buildBookmarksList() {
    return Container(
      color: _isDarkMode ? Colors.grey[900] : Colors.white, // Adjust background for dark mode
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Bookmarks",
                style: titleStyle.copyWith(color: _isDarkMode ? Colors.white : Colors.black),
              ),
              IconButton(
                icon: Icon(Icons.close, color: _isDarkMode ? Colors.white : Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_bookmarks.isEmpty)
            Center(
              child: Text(
                "No bookmarks yet.",
                style: subtitleStyle.copyWith(color: _isDarkMode ? Colors.white70 : Colors.black54),
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: _bookmarks.length,
                itemBuilder: (context, index) {
                  final weather = _bookmarks[index];
                  final isCurrentLocation = _currentLocationCity != null && _currentLocationCity == weather.cityName;

                  // Convert temperatures to Fahrenheit if Imperial is selected
                  final temperature = _isMetric
                      ? weather.temperature
                      : (weather.temperature * 9 / 5) + 32;
                  final feelsLike = _isMetric
                      ? weather.feelsLike
                      : (weather.feelsLike * 9 / 5) + 32;
                  final tempMin = _isMetric
                      ? weather.tempMin
                      : (weather.tempMin * 9 / 5) + 32;
                  final tempMax = _isMetric
                      ? weather.tempMax
                      : (weather.tempMax * 9 / 5) + 32;

                  return ListTile(
                    tileColor: _isDarkMode ? Colors.grey[900] : Colors.white, // Adjust tile background for dark mode
                    title: Text(
                      "${weather.cityName}, ${weather.country}",
                      style: titleStyle.copyWith(color: _isDarkMode ? Colors.white : Colors.black),
                    ),
                    subtitle: Text(
                      "${temperature.round()}°${_isMetric ? 'C' : 'F'} - ${getFriendlyCondition(weather.mainCondition)}",
                      style: subtitleStyle.copyWith(color: _isDarkMode ? Colors.white70 : Colors.black54),
                    ),
                    trailing: isCurrentLocation
                        ? IconButton(
                            icon: Icon(Icons.location_on, color: _isDarkMode ? Colors.white : Colors.black),
                            onPressed: null,
                          )
                        : IconButton(
                            icon: Icon(Icons.delete, color: _isDarkMode ? Colors.white : Colors.black),
                            onPressed: () async {
                              final shouldDelete = await showDialog<bool>(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.white,
                                    title: Text(
                                      "Delete Bookmark",
                                      style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
                                    ),
                                    content: Text(
                                      "Are you sure you want to delete this bookmark?",
                                      style: TextStyle(color: _isDarkMode ? Colors.white70 : Colors.black54),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: Text("Cancel", style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black)),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: Text("Delete", style: TextStyle(color: _isDarkMode ? Colors.red : Colors.red)),
                                      ),
                                    ],
                                  );
                                },
                              );

                              if (shouldDelete == true) {
                                removeBookmark(weather.cityName);
                                Navigator.pop(context);
                              }
                            },
                          ),
                    onTap: () {
                      setState(() {
                        // Update the _weather object with the selected bookmarked city
                        _weather = Weather(
                          cityName: weather.cityName,
                          country: weather.country,
                          temperature: _isMetric ? weather.temperature : (weather.temperature * 9 / 5) + 32,
                          feelsLike: _isMetric ? weather.feelsLike : (weather.feelsLike * 9 / 5) + 32,
                          tempMin: _isMetric ? weather.tempMin : (weather.tempMin * 9 / 5) + 32,
                          tempMax: _isMetric ? weather.tempMax : (weather.tempMax * 9 / 5) + 32,
                          humidity: weather.humidity,
                          windSpeed: weather.windSpeed,
                          visibility: weather.visibility,
                          mainCondition: weather.mainCondition,
                        );
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  String getWeatherAnimation(String condition) {
    switch (condition) {
      case 'Clear':
        return 'assets/sun.json';
      case 'Clouds':
        return 'assets/cloudy.json';
      case 'Rain':
      case 'Drizzle':
        return 'assets/rain.json';
      case 'Thunderstorm':
        return 'assets/thunder.json';
      case 'Snow':
        return 'assets/snow.json';
      case 'Mist':
      case 'Fog':
      case 'Haze':
        return 'assets/fog.json';
      default:
        return 'assets/sun.json';
    }
  }
}

// Reusable SearchBar widget
class SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSearch;
  final VoidCallback onOpenBookmarks;
  final bool isDarkMode;

  const SearchBar({
    required this.controller,
    required this.onSearch,
    required this.onOpenBookmarks,
    required this.isDarkMode,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.bookmark_border, color: isDarkMode ? Colors.white : iconColor),
          onPressed: onOpenBookmarks,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: controller,
            style: TextStyle(color: isDarkMode ? Colors.white : primaryTextColor),
            decoration: InputDecoration(
              filled: true,
              fillColor: isDarkMode ? Colors.grey[800] : Colors.white, // Adjust background for dark mode
              hintText: 'Search city...',
              hintStyle: TextStyle(color: isDarkMode ? Colors.white70 : secondaryTextColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: isDarkMode ? Colors.white : iconColor, width: 3.0),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: isDarkMode ? Colors.white : iconColor, width: 3.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: isDarkMode ? Colors.white : iconColor, width: 4.0),
              ),
              suffixIcon: IconButton(
                icon: Icon(Icons.clear, color: isDarkMode ? Colors.white : iconColor),
                onPressed: () {
                  controller.clear();
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          icon: Icon(Icons.search, color: isDarkMode ? Colors.white : iconColor),
          onPressed: onSearch,
        ),
      ],
    );
  }
}

