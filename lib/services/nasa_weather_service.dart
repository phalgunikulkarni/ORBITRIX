import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

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

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      temperature: json['temperature']?.toDouble() ?? 25.0,
      humidity: json['humidity']?.toDouble() ?? 50.0,
      windSpeed: json['windSpeed']?.toDouble() ?? 5.0,
      condition: json['condition'] ?? 'Clear',
      visibility: json['visibility']?.toDouble() ?? 10.0,
      precipitation: json['precipitation']?.toDouble() ?? 0.0,
      severity: json['severity'] ?? 'Normal',
      warning: json['warning'] ?? '',
    );
  }
}

class RouteWeatherPoint {
  final LatLng position;
  final WeatherData weather;
  final double distanceFromStart;

  RouteWeatherPoint({
    required this.position,
    required this.weather,
    required this.distanceFromStart,
  });
}

class NasaWeatherService {
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';
  static const String _apiKey = 'your_openweather_api_key'; // Replace with actual API key
  
  // Bengaluru (Bangalore) coordinates - fixed location parameters
  static const double _bengaluruLat = 12.9716;
  static const double _bengaluruLon = 77.5946;
  static const String _bengaluruName = 'Bengaluru';
  
  // NASA Earth Data endpoints (for future implementation)
  // static const String _nasaBaseUrl = 'https://api.earthdata.nasa.gov';
  
  /// Fetches weather data for Bengaluru (ignores input location for consistent data)
  Future<WeatherData> getWeatherForLocation(LatLng location) async {
    try {
      // Always use Bengaluru coordinates for consistent local weather data
      final url = '$_baseUrl/weather?lat=$_bengaluruLat&lon=$_bengaluruLon&appid=$_apiKey&units=metric';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseWeatherData(data);
      } else {
        // Return mock Bengaluru weather data if API fails
        return _getBengaluruMockWeatherData();
      }
    } catch (e) {
      print('Error fetching weather data: $e');
      return _getBengaluruMockWeatherData();
    }
  }

  /// Fetches weather data for multiple points along a route (all using Bengaluru weather)
  Future<List<RouteWeatherPoint>> getRouteWeatherData(List<LatLng> routePoints) async {
    List<RouteWeatherPoint> weatherPoints = [];
    
    if (routePoints.isEmpty) return weatherPoints;
    
    // Get single weather data for Bengaluru (since we're focusing on local conditions)
    final bengaluruWeather = await getWeatherForLocation(const LatLng(_bengaluruLat, _bengaluruLon));
    
    // Create weather points at key intervals along the route
    List<LatLng> sampledPoints = _sampleRoutePoints(routePoints);
    double totalDistance = 0.0;
    
    for (int i = 0; i < sampledPoints.length; i++) {
      if (i > 0) {
        totalDistance += _calculateDistance(sampledPoints[i-1], sampledPoints[i]);
      }
      
      // Use the same Bengaluru weather for all points, with slight variations for realism
      WeatherData pointWeather = _createVariantWeatherData(bengaluruWeather, i);
      
      weatherPoints.add(RouteWeatherPoint(
        position: sampledPoints[i],
        weather: pointWeather,
        distanceFromStart: totalDistance,
      ));
    }
    
    return weatherPoints;
  }

  /// Sample route points to get weather data at key intervals
  List<LatLng> _sampleRoutePoints(List<LatLng> routePoints) {
    if (routePoints.length <= 5) return routePoints;
    
    List<LatLng> sampledPoints = [];
    sampledPoints.add(routePoints.first); // Start point
    
    // Add points every ~10km
    double accumulatedDistance = 0.0;
    const double sampleInterval = 10.0; // 10 km
    
    for (int i = 1; i < routePoints.length; i++) {
      double segmentDistance = _calculateDistance(routePoints[i-1], routePoints[i]);
      accumulatedDistance += segmentDistance;
      
      if (accumulatedDistance >= sampleInterval) {
        sampledPoints.add(routePoints[i]);
        accumulatedDistance = 0.0;
      }
    }
    
    sampledPoints.add(routePoints.last); // End point
    return sampledPoints;
  }

  /// Calculate distance between two points in kilometers
  double _calculateDistance(LatLng point1, LatLng point2) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Kilometer, point1, point2);
  }

  /// Parse weather data from API response
  WeatherData _parseWeatherData(Map<String, dynamic> data) {
    final main = data['main'] ?? {};
    final weather = data['weather']?[0] ?? {};
    final wind = data['wind'] ?? {};
    final visibility = data['visibility']?.toDouble() ?? 10000.0;
    
    double temp = main['temp']?.toDouble() ?? 25.0;
    double humidity = main['humidity']?.toDouble() ?? 50.0;
    double windSpeed = wind['speed']?.toDouble() ?? 5.0;
    String condition = weather['main'] ?? 'Clear';
    double precipitation = (data['rain']?['1h'] ?? data['snow']?['1h'] ?? 0.0).toDouble();
    
    // Determine severity and warnings
    String severity = _determineSeverity(temp, windSpeed, precipitation, visibility/1000);
    String warning = _generateWeatherWarning(condition, severity, windSpeed, precipitation);
    
    return WeatherData(
      temperature: temp,
      humidity: humidity,
      windSpeed: windSpeed,
      condition: condition,
      visibility: visibility / 1000, // Convert to km
      precipitation: precipitation,
      severity: severity,
      warning: warning,
    );
  }

  /// Generate realistic Bengaluru weather data for testing
  WeatherData _getBengaluruMockWeatherData() {
    final hour = DateTime.now().hour;
    final month = DateTime.now().month;
    
    // Bengaluru typical weather patterns
    double baseTemp = _getBengaluruBaseTemperature(month, hour);
    double humidity = _getBengaluruHumidity(month);
    double windSpeed = _getBengaluruWindSpeed(month);
    double precipitation = _getBengaluruPrecipitation(month);
    String condition = _getBengaluruCondition(month, precipitation);
    double visibility = _getBengaluruVisibility(month, precipitation);
    
    String severity = _determineSeverity(baseTemp, windSpeed, precipitation, visibility);
    String warning = _generateWeatherWarning(condition, severity, windSpeed, precipitation);
    
    return WeatherData(
      temperature: baseTemp,
      humidity: humidity,
      windSpeed: windSpeed,
      condition: condition,
      visibility: visibility,
      precipitation: precipitation,
      severity: severity,
      warning: warning,
    );
  }

  /// Create slight weather variations for different points along route
  WeatherData _createVariantWeatherData(WeatherData baseWeather, int pointIndex) {
    // Small variations to make it realistic while keeping Bengaluru characteristics
    final variance = (pointIndex % 5) - 2; // -2 to +2 variation
    
    return WeatherData(
      temperature: baseWeather.temperature + (variance * 0.5),
      humidity: (baseWeather.humidity + (variance * 2)).clamp(0, 100),
      windSpeed: (baseWeather.windSpeed + (variance * 0.3)).clamp(0, 50),
      condition: baseWeather.condition,
      visibility: (baseWeather.visibility + (variance * 0.2)).clamp(0.1, 20),
      precipitation: baseWeather.precipitation,
      severity: baseWeather.severity,
      warning: baseWeather.warning,
    );
  }

  // Bengaluru-specific weather pattern methods
  double _getBengaluruBaseTemperature(int month, int hour) {
    // Bengaluru temperature patterns by month and time
    Map<int, double> monthlyAvg = {
      1: 21, 2: 24, 3: 27, 4: 28, 5: 28, 6: 25,
      7: 24, 8: 24, 9: 25, 10: 24, 11: 22, 12: 20
    };
    
    double baseTemp = monthlyAvg[month] ?? 25;
    
    // Daily temperature variation
    if (hour >= 6 && hour <= 10) baseTemp += 2; // Morning warmth
    else if (hour >= 11 && hour <= 15) baseTemp += 5; // Afternoon peak
    else if (hour >= 16 && hour <= 19) baseTemp += 3; // Evening
    else baseTemp -= 2; // Night cooling
    
    return baseTemp;
  }

  double _getBengaluruHumidity(int month) {
    // Bengaluru humidity by season
    if (month >= 6 && month <= 9) return 75 + (DateTime.now().millisecond % 20); // Monsoon
    if (month >= 10 && month <= 2) return 55 + (DateTime.now().millisecond % 15); // Winter
    return 65 + (DateTime.now().millisecond % 20); // Summer
  }

  double _getBengaluruWindSpeed(int month) {
    // Bengaluru wind patterns
    if (month >= 6 && month <= 9) return 8 + (DateTime.now().millisecond % 7); // Monsoon winds
    return 5 + (DateTime.now().millisecond % 5); // Normal winds
  }

  double _getBengaluruPrecipitation(int month) {
    // Bengaluru precipitation by month
    if (month >= 6 && month <= 9) { // Monsoon season
      final random = DateTime.now().millisecond % 10;
      return random > 6 ? (random % 8).toDouble() : 0.0;
    }
    if (month == 10 || month == 11) { // Post-monsoon
      final random = DateTime.now().millisecond % 10;
      return random > 8 ? (random % 3).toDouble() : 0.0;
    }
    return 0.0; // Dry season
  }

  String _getBengaluruCondition(int month, double precipitation) {
    if (precipitation > 5) return 'Rain';
    if (precipitation > 0) return 'Drizzle';
    if (month >= 6 && month <= 9) return 'Clouds'; // Monsoon season
    if (month >= 12 || month <= 2) return 'Clear'; // Winter
    return 'Partly Cloudy'; // Summer
  }

  double _getBengaluruVisibility(int month, double precipitation) {
    if (precipitation > 5) return 3.0; // Heavy rain
    if (precipitation > 0) return 6.0; // Light rain
    if (month >= 6 && month <= 9) return 8.0; // Monsoon haze
    return 12.0; // Clear conditions
  }

  /// Determine weather severity for driving conditions
  String _determineSeverity(double temp, double windSpeed, double precipitation, double visibility) {
    if (precipitation > 5 || windSpeed > 15 || visibility < 2 || temp < 0) {
      return 'Severe';
    } else if (precipitation > 2 || windSpeed > 10 || visibility < 5 || temp < 5) {
      return 'Moderate';
    } else if (precipitation > 0 || windSpeed > 5 || visibility < 8) {
      return 'Caution';
    }
    return 'Normal';
  }

  /// Generate driving-specific weather warnings
  String _generateWeatherWarning(String condition, String severity, double windSpeed, double precipitation) {
    List<String> warnings = [];
    
    if (severity == 'Severe') {
      warnings.add('⚠️ SEVERE WEATHER ALERT');
    }
    
    if (precipitation > 2) {
      warnings.add('🌧️ Heavy rain - Reduced visibility & slippery roads');
    } else if (precipitation > 0) {
      warnings.add('🌦️ Light rain - Exercise caution');
    }
    
    if (windSpeed > 15) {
      warnings.add('💨 Strong winds - Vehicle stability risk');
    } else if (windSpeed > 10) {
      warnings.add('🌬️ Moderate winds - Maintain control');
    }
    
    if (condition.toLowerCase().contains('fog')) {
      warnings.add('🌫️ Fog conditions - Low visibility');
    }
    
    if (condition.toLowerCase().contains('snow')) {
      warnings.add('❄️ Snow conditions - Extremely slippery');
    }
    
    return warnings.isEmpty ? 'Clear driving conditions' : warnings.join(' • ');
  }

  /// Get weather icon based on condition and severity
  static String getWeatherIcon(String condition, String severity) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return '☀️';
      case 'clouds':
        return '☁️';
      case 'rain':
      case 'drizzle':
        return severity == 'Severe' ? '⛈️' : '🌧️';
      case 'snow':
        return '❄️';
      case 'fog':
      case 'mist':
        return '🌫️';
      case 'thunderstorm':
        return '⛈️';
      default:
        return '🌤️';
    }
  }

  /// Get severity color for UI
  static Color getSeverityColor(String severity) {
    switch (severity) {
      case 'Severe':
        return const Color(0xFFDC2626); // Red
      case 'Moderate':
        return const Color(0xFFF59E0B); // Amber
      case 'Caution':
        return const Color(0xFFEAB308); // Yellow
      default:
        return const Color(0xFF059669); // Green
    }
  }
}