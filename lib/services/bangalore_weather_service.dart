import 'package:flutter/material.dart';

// Simple location class to avoid external dependencies
class Location {
  final double latitude;
  final double longitude;

  Location({required this.latitude, required this.longitude});
}

class WeatherData {
  final double temperature;
  final double humidity;
  final double windSpeed;
  final String condition;
  final double visibility;
  final double precipitation;
  final String severity;
  final String warning;

  WeatherData({
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.condition,
    required this.visibility,
    required this.precipitation,
    required this.severity,
    required this.warning,
  });
}

class RouteWeatherPoint {
  final Location location;
  final WeatherData weather;
  final double distanceFromStart;

  RouteWeatherPoint({
    required this.location,
    required this.weather,
    required this.distanceFromStart,
  });
}

class BangaloreWeatherService {
  // Bengaluru coordinates (for reference)
  static const double bengaluruLat = 12.9716;
  static const double bengaluruLon = 77.5946;

  // Real Bangalore weather patterns based on IMD historical data
  static const Map<int, Map<String, dynamic>> _bangaloreWeatherPatterns = {
    1: {'temp': 21, 'humidity': 60, 'rainfall': 5, 'condition': 'Clear', 'wind': 3}, // January - Cool & Dry
    2: {'temp': 24, 'humidity': 55, 'rainfall': 8, 'condition': 'Clear', 'wind': 4}, // February - Pleasant
    3: {'temp': 27, 'humidity': 50, 'rainfall': 15, 'condition': 'Partly Cloudy', 'wind': 5}, // March - Warming
    4: {'temp': 29, 'humidity': 55, 'rainfall': 35, 'condition': 'Partly Cloudy', 'wind': 6}, // April - Hot
    5: {'temp': 28, 'humidity': 65, 'rainfall': 90, 'condition': 'Clouds', 'wind': 7}, // May - Pre-monsoon
    6: {'temp': 25, 'humidity': 75, 'rainfall': 95, 'condition': 'Rain', 'wind': 8}, // June - SW Monsoon
    7: {'temp': 24, 'humidity': 80, 'rainfall': 110, 'condition': 'Rain', 'wind': 9}, // July - Peak Monsoon
    8: {'temp': 24, 'humidity': 80, 'rainfall': 125, 'condition': 'Rain', 'wind': 8}, // August - Heavy Rain
    9: {'temp': 25, 'humidity': 75, 'rainfall': 160, 'condition': 'Rain', 'wind': 7}, // September - NE Monsoon
    10: {'temp': 24, 'humidity': 70, 'rainfall': 180, 'condition': 'Rain', 'wind': 6}, // October - Post Monsoon
    11: {'temp': 22, 'humidity': 65, 'rainfall': 45, 'condition': 'Clouds', 'wind': 4}, // November - Retreating
    12: {'temp': 20, 'humidity': 65, 'rainfall': 15, 'condition': 'Clear', 'wind': 3}, // December - Winter
  };

  /// Get instant weather data for Bangalore (no API calls - immediate response)
  Future<WeatherData> getWeatherForLocation(Location location) async {
    return _getBangaloreCurrentWeather();
  }

  /// Get weather data for multiple points along a route (all Bangalore-based)
  Future<List<RouteWeatherPoint>> getRouteWeatherData(List<Location> routePoints) async {
    List<RouteWeatherPoint> weatherPoints = [];
    
    // Get base Bangalore weather
    WeatherData baseWeather = _getBangaloreCurrentWeather();
    
    for (int i = 0; i < routePoints.length; i++) {
      double distance = i * 2.0; // 2km intervals for city routes
      
      // Create slight variations for different areas of Bangalore
      WeatherData pointWeather = _createBangaloreVariation(baseWeather, i);
      
      weatherPoints.add(RouteWeatherPoint(
        location: routePoints[i],
        weather: pointWeather,
        distanceFromStart: distance,
      ));
    }
    
    return weatherPoints;
  }

  /// Get current Bangalore weather based on real seasonal patterns
  WeatherData _getBangaloreCurrentWeather() {
    final now = DateTime.now();
    final month = now.month;
    final hour = now.hour;
    
    // Get base pattern for current month
    final pattern = _bangaloreWeatherPatterns[month]!;
    
    // Apply daily variations
    double temperature = _adjustTemperatureForTime(pattern['temp'].toDouble(), hour);
    double humidity = pattern['humidity'].toDouble();
    double rainfall = pattern['rainfall'].toDouble();
    String condition = pattern['condition'];
    double windSpeed = pattern['wind'].toDouble();
    
    // Determine if it's currently raining based on seasonal probability
    bool isRaining = _isCurrentlyRaining(month, hour, rainfall);
    if (isRaining) {
      condition = 'Rain';
      humidity = (humidity + 10).clamp(0, 100);
      temperature -= 2; // Rain cools temperature
    }
    
    // Calculate visibility and precipitation
    double visibility = _calculateVisibility(condition, isRaining);
    double currentPrecipitation = isRaining ? _getCurrentRainfall(rainfall) : 0.0;
    
    // Determine severity and warnings
    String severity = _determineSeverity(temperature, windSpeed, currentPrecipitation, visibility);
    String warning = _generateBangaloreWarning(condition, severity, temperature, currentPrecipitation);
    
    return WeatherData(
      temperature: temperature,
      humidity: humidity,
      windSpeed: windSpeed,
      condition: condition,
      visibility: visibility,
      precipitation: currentPrecipitation,
      severity: severity,
      warning: warning,
    );
  }

  /// Adjust temperature based on time of day (Bangalore patterns)
  double _adjustTemperatureForTime(double baseTemp, int hour) {
    if (hour >= 6 && hour <= 9) return baseTemp + 1; // Morning warming
    if (hour >= 10 && hour <= 15) return baseTemp + 4; // Afternoon peak
    if (hour >= 16 && hour <= 19) return baseTemp + 2; // Evening warmth
    if (hour >= 20 && hour <= 22) return baseTemp - 1; // Evening cooling
    return baseTemp - 3; // Night cooling
  }

  /// Determine if it's currently raining based on Bangalore patterns
  bool _isCurrentlyRaining(int month, int hour, double monthlyRainfall) {
    // Higher probability during monsoon months (June-October)
    if (month >= 6 && month <= 10) {
      // More likely to rain in evening/night in Bangalore
      if (hour >= 15 && hour <= 21) return DateTime.now().millisecond % 3 == 0; // 33% chance
      return DateTime.now().millisecond % 5 == 0; // 20% chance other times
    }
    
    // Pre/post monsoon light rain probability
    if (month == 5 || month == 11) {
      return DateTime.now().millisecond % 8 == 0; // 12.5% chance
    }
    
    // Very low probability in dry months
    return DateTime.now().millisecond % 20 == 0; // 5% chance
  }

  /// Calculate current rainfall amount
  double _getCurrentRainfall(double monthlyAverage) {
    // Convert monthly average to current intensity
    final intensity = DateTime.now().millisecond % 10;
    if (intensity < 3) return 2.0; // Light rain
    if (intensity < 7) return 5.0; // Moderate rain
    return 8.0; // Heavy rain
  }

  /// Calculate visibility based on conditions
  double _calculateVisibility(String condition, bool isRaining) {
    switch (condition) {
      case 'Rain': return isRaining ? 4.0 : 8.0;
      case 'Clouds': return 8.0;
      case 'Fog': return 2.0;
      default: return 12.0; // Clear conditions
    }
  }

  /// Create weather variations for different areas of Bangalore
  WeatherData _createBangaloreVariation(WeatherData baseWeather, int areaIndex) {
    // Different areas of Bangalore have slight variations
    final variations = [
      {'temp': 0, 'humidity': 0, 'name': 'Central Bangalore'}, // City center
      {'temp': -1, 'humidity': 5, 'name': 'Electronic City'}, // South - slightly cooler
      {'temp': 1, 'humidity': -3, 'name': 'Whitefield'}, // East - warmer, less humid
      {'temp': -0.5, 'humidity': 3, 'name': 'Hebbal'}, // North - airport area
      {'temp': 0.5, 'humidity': -2, 'name': 'Banashankari'}, // South - residential
    ];
    
    final variation = variations[areaIndex % variations.length];
    
    return WeatherData(
      temperature: baseWeather.temperature + (variation['temp']! as num).toDouble(),
      humidity: (baseWeather.humidity + (variation['humidity']! as num).toDouble()).clamp(0, 100),
      windSpeed: baseWeather.windSpeed + (areaIndex % 3 - 1) * 0.5, // ±0.5 variation
      condition: baseWeather.condition,
      visibility: baseWeather.visibility,
      precipitation: baseWeather.precipitation,
      severity: baseWeather.severity,
      warning: baseWeather.warning,
    );
  }

  /// Determine weather severity for Bangalore conditions
  String _determineSeverity(double temp, double windSpeed, double precipitation, double visibility) {
    if (precipitation > 7 || temp > 35 || temp < 15 || visibility < 3) return 'severe';
    if (precipitation > 3 || temp > 32 || temp < 18 || visibility < 6) return 'moderate';
    return 'normal';
  }

  /// Generate Bangalore-specific weather warnings
  String _generateBangaloreWarning(String condition, String severity, double temp, double precipitation) {
    List<String> warnings = [];
    
    if (severity == 'severe') {
      if (precipitation > 7) warnings.add('Heavy rainfall - flooding possible in low-lying areas');
      if (temp > 35) warnings.add('High temperature - stay hydrated');
      if (temp < 15) warnings.add('Unusually cold for Bangalore - dress warmly');
    }
    
    if (severity == 'moderate') {
      if (precipitation > 3) warnings.add('Moderate rain - carry umbrella, possible traffic delays');
      if (temp > 32) warnings.add('Hot weather - avoid prolonged sun exposure');
    }
    
    // Bangalore-specific traffic warnings
    if (condition == 'Rain') {
      warnings.add('Traffic congestion expected on major routes - allow extra time');
    }
    
    return warnings.join('. ');
  }

  /// Get color for weather severity level
  static Color getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'severe': return const Color(0xFFE74C3C); // Red
      case 'moderate': return const Color(0xFFF39C12); // Orange  
      default: return const Color(0xFF27AE60); // Green
    }
  }

  /// Get weather icon based on condition and severity
  static Icon getWeatherIcon(String condition, String severity) {
    IconData iconData;
    Color iconColor = getSeverityColor(severity);
    
    switch (condition.toLowerCase()) {
      case 'rain':
      case 'drizzle':
        iconData = Icons.water_drop;
        break;
      case 'clouds':
      case 'partly cloudy':
        iconData = Icons.cloud;
        break;
      case 'clear':
        iconData = Icons.wb_sunny;
        break;
      case 'fog':
        iconData = Icons.foggy;
        break;
      default:
        iconData = Icons.wb_cloudy;
    }
    
    return Icon(iconData, color: iconColor, size: 24);
  }
}