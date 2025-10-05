import 'package:flutter/material.dart';
import '../services/nasa_enhanced_weather_service.dart';

class WeatherWidget extends StatelessWidget {
  final WeatherData weather;
  final bool isCompact;

  const WeatherWidget({
    super.key,
    required this.weather,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 8 : 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            NasaEnhancedWeatherService.getSeverityColor(weather.severity).withOpacity(0.8),
            NasaEnhancedWeatherService.getSeverityColor(weather.severity).withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(isCompact ? 8 : 12),
        boxShadow: [
          BoxShadow(
            color: NasaEnhancedWeatherService.getSeverityColor(weather.severity).withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: isCompact ? _buildCompactView() : _buildDetailedView(),
    );
  }

  Widget _buildCompactView() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        NasaEnhancedWeatherService.getWeatherIcon(weather.condition, weather.severity),
        const SizedBox(width: 4),
        Text(
          '${weather.temperature.round()}°C',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (weather.precipitation > 0) ...[
          const SizedBox(width: 4),
          const Icon(Icons.water_drop, color: Colors.white, size: 12),
        ],
      ],
    );
  }

  Widget _buildDetailedView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header with icon and temperature
        Row(
          children: [
            NasaEnhancedWeatherService.getWeatherIcon(weather.condition, weather.severity),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${weather.temperature.round()}°C',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  weather.condition,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                weather.severity,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Weather details
        Row(
          children: [
            _buildWeatherDetail(Icons.visibility, '${weather.visibility.toStringAsFixed(1)}km'),
            const SizedBox(width: 12),
            _buildWeatherDetail(Icons.air, '${weather.windSpeed.round()} km/h'),
            const SizedBox(width: 12),
            _buildWeatherDetail(Icons.water_drop, '${weather.humidity.round()}%'),
          ],
        ),
        
        if (weather.precipitation > 0) ...[
          const SizedBox(height: 4),
          _buildWeatherDetail(Icons.grain, '${weather.precipitation.toStringAsFixed(1)}mm'),
        ],
        
        if (weather.warning.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Text(
              weather.warning,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildWeatherDetail(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 14),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class RouteWeatherOverlay extends StatelessWidget {
  final List<RouteWeatherPoint> weatherPoints;
  final double currentDistanceTraveled;

  const RouteWeatherOverlay({
    super.key,
    required this.weatherPoints,
    this.currentDistanceTraveled = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    if (weatherPoints.isEmpty) return const SizedBox.shrink();

    // Find the current and next weather points
    RouteWeatherPoint currentWeather = weatherPoints.first;
    RouteWeatherPoint? nextWeather;

    for (int i = 0; i < weatherPoints.length - 1; i++) {
      if (currentDistanceTraveled >= weatherPoints[i].distanceFromStart &&
          currentDistanceTraveled < weatherPoints[i + 1].distanceFromStart) {
        currentWeather = weatherPoints[i];
        nextWeather = weatherPoints[i + 1];
        break;
      }
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current weather
          WeatherWidget(weather: currentWeather.weather),
          
          if (nextWeather != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.arrow_forward, color: Colors.white70, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Next: ${(nextWeather.distanceFromStart - currentDistanceTraveled).toStringAsFixed(1)}km',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                  WeatherWidget(weather: nextWeather.weather, isCompact: true),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class WeatherAlertDialog extends StatelessWidget {
  final List<RouteWeatherPoint> weatherPoints;

  const WeatherAlertDialog({
    super.key,
    required this.weatherPoints,
  });

  @override
  Widget build(BuildContext context) {
    final severeWeather = weatherPoints.where((point) => 
      point.weather.severity == 'Severe' || point.weather.severity == 'Moderate'
    ).toList();

    if (severeWeather.isEmpty) return const SizedBox.shrink();

    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.warning_amber, color: Colors.amber, size: 24),
          SizedBox(width: 8),
          Text(
            'Weather Alert',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Severe weather conditions detected along your route:',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 12),
          ...severeWeather.map((point) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${point.distanceFromStart.toStringAsFixed(1)}km:',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    point.weather.warning,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Continue', style: TextStyle(color: Colors.blue)),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            // Could add route recalculation here
          },
          child: const Text('Find Alternative', style: TextStyle(color: Colors.amber)),
        ),
      ],
    );
  }
}