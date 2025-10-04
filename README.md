# ORBITRIX

ORBITRIX is a Vehicle-to-Vehicle (V2V) Safety Alert app built using Flutter. It uses smartphone sensors, Bluetooth Low Energy (BLE), GPS, and cloud integration to detect and share real-time road hazard alerts and improve driver safety.

## Features

- Real-time detection and alerting of nearby vehicles using BLE.
- Pothole and sudden brake detection via accelerometer and gyroscope sensors.
- Interactive maps with OpenStreetMap to visualize nearby vehicles and hazards.
- Integration with NASA datasets for environmental hazard validation.
- Traffic congestion prediction using Kaggle machine learning models.
- Destination search powered by Google Places API.

## Getting Started

### Prerequisites

- Flutter SDK (version >= 2.17.0 < 4.0.0)
- Android Studio or Visual Studio Code
- An Android or iOS device/emulator

### Installation

1. Clone the repository: https://github.com/phalgunikulkarni/ORBITRIX.git
 
2. Install dependencies

3. Add your Firebase configuration files:

- Place `google-services.json` in `android/app/`
- Place `GoogleService-Info.plist` in `ios/Runner/` (if iOS support added)

4. Run the app: flutter run


## Usage

- Enable Bluetooth and Location permissions when prompted.
- The app will detect nearby devices and listen for hazard alerts.
- View real-time vehicle locations and hazards on the map.
- Use the search bar powered by Google Places to find destinations.

## Project Structure

- `/lib` - Flutter Dart source code
- `/android` and `/ios` - Platform-specific build files and configurations
- `/assets` - Static assets like images and JSON files
- `/scripts` - Data processing or ML scripts (if any)

## Data Sources

- NASA environmental and hazard datasets
- Kaggle traffic congestion algorithms
- Google Places API


