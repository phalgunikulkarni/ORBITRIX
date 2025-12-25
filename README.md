ORBITRIX 🚗⚠️

Vehicle-to-Vehicle (V2V) Road Safety & Navigation Platform

ORBITRIX is a Flutter-based Vehicle-to-Vehicle (V2V) safety and navigation application designed to enhance road safety using smartphones as intelligent sensing nodes. It leverages GPS, Bluetooth Low Energy (BLE), motion sensors, and cloud intelligence to detect, share, and visualize real-time road hazards and nearby vehicle risks.

The system demonstrates how low-cost consumer devices can complement or augment traditional vehicle safety systems, making advanced road awareness accessible even in resource-constrained environments.

🚀 Key Features
🔹 Vehicle-to-Vehicle (V2V) Safety

Real-time detection of nearby vehicles using BLE and GPS

Distance-based proximity alerts with visual, vibration, and audio warnings

Adaptive risk levels based on distance, motion, and confidence scoring

🔹 Road Hazard Detection

Pothole and sudden braking detection using accelerometer and gyroscope data

Crowdsourced hazard sharing between nearby devices

Confidence-based filtering to reduce false positives

🔹 Intelligent Navigation

Interactive maps using OpenStreetMap

Route visualization with live vehicle and hazard overlays

Destination search and autocomplete powered by Google Places API

🔹 Environmental Awareness

Integration with NASA datasets for weather and environmental hazard insights

Context-aware alerts for rain, fog, poor visibility, and adverse conditions

🔹 Traffic Intelligence

Traffic congestion estimation using machine learning models trained on Kaggle datasets

Route-level congestion awareness to support safer driving decisions

🧠 Future Scope & Vision
🚘 Driverless & Assisted Vehicles

ORBITRIX can act as a software-layer safety companion for autonomous and semi-autonomous vehicles

Provides redundancy to onboard sensors (LiDAR/Radar) through cooperative V2V awareness

Enables safer navigation in GPS-challenged or sensor-limited environments

🌐 IoT & Smart Infrastructure Integration

Can be extended to integrate with roadside IoT devices (smart traffic lights, road sensors)

Mobile phones can act as temporary base stations for indoor or urban canyon navigation

Supports Vehicle-to-Infrastructure (V2I) communication for smart city applications

🛠️ Tech Stack

Frontend: Flutter (Android/iOS)

Mapping: OpenStreetMap (via FlutterMap)

Location & Sensors: GPS, Accelerometer, Gyroscope

Connectivity: Bluetooth Low Energy (BLE)

APIs & Data:

Google Places API

NASA environmental datasets

Kaggle ML traffic models

Backend (Optional): Firebase / Node.js REST services

📦 Getting Started
Prerequisites

Flutter SDK (>= 2.17.0, < 4.0.0)

Android Studio or VS Code

Android/iOS device or emulator

Installation

Clone the repository:

git clone https://github.com/phalgunikulkarni/ORBITRIX.git
cd ORBITRIX


Install dependencies:

flutter pub get


Add Firebase configuration (optional but recommended):

android/app/google-services.json

ios/Runner/GoogleService-Info.plist

Run the app:

flutter run

📱 Usage

Grant Bluetooth and Location permissions when prompted

Start navigation by selecting a destination

View nearby vehicles, hazards, traffic, and weather on the map

Receive real-time alerts for proximity risks and road conditions

📂 Project Structure
/lib        → Flutter source code
/android    → Android platform files
/ios        → iOS platform files
/assets     → Static assets and data files
/scripts    → Data processing / ML scripts (if any)

📊 Data Sources

NASA – Environmental and weather datasets

Kaggle – Traffic congestion and ML models

Google Places API – Destination search and autocomplete

🎯 Why ORBITRIX?

ORBITRIX demonstrates how software-first, cooperative sensing can improve road safety without relying on expensive hardware. It is suitable for hackathons, research, smart mobility prototypes, and future integration into autonomous and connected vehicle ecosystems.

If you want, I can also:

Shorten this for a hackathon submission

Add architecture diagrams

Rewrite it in a research-paper tone

Create a NASA Space Apps–style abstract

Just tell me.
