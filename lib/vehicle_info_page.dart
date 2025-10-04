import 'package:flutter/material.dart';
import 'dashboard_screen.dart';

class VehicleInfoPage extends StatefulWidget {
  const VehicleInfoPage({super.key});

  @override
  State<VehicleInfoPage> createState() => _VehicleInfoPageState();
}

class _VehicleInfoPageState extends State<VehicleInfoPage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedCategory;
  String? _selectedVehicleType;
  String? _selectedSUVCategory;
  final List<String> _suvCategories = [
    'Compact',
    'Mid-Size',
    'Full-Size',
  ];

  // Organized vehicle types by category
  final Map<String, List<String>> _vehicleCategories = {
    'Cars': [
      'Sedan',
      'Hatchback',
      'SUV (Sport Utility Vehicle)',
      'MUV/MPV (Multi Utility/Purpose Vehicle)',
      'Coupe',
      'Convertible',
      'Wagon/Estate',
      'Crossover',
      'Luxury Car',
      'Sports Car',
    ],
    'Trucks': [
      'Small Truck/LCV',
      'Medium Truck',
      'Heavy Truck/Trailer',
      'Garbage Truck',
      'Tanker/Petroleum Truck',
      'Refrigerated Truck',
      'Dump Truck',
      'Flatbed Truck',
      'Container Truck',
      'Pickup Truck',
    ],
    'Buses': [
      'Mini Bus/Van',
      'City Bus',
      'Tourist/Coach Bus',
      'School Bus',
      'Articulated/Double Decker Bus',
    ],
    'Two-Wheelers': [
      'Motorcycle',
      'Scooter',
      'Moped',
      'Electric Bike',
    ],
    'Three-Wheelers': [
      'Auto Rickshaw',
      'Cargo Rickshaw',
      'E-Rickshaw',
    ],
    'Specialized Vehicles': [
      'Ambulance',
      'Fire Truck',
      'Police Van',
      'Construction Vehicle (JCB, Crane, etc.)',
      'Tractor/Farm Vehicle',
      'Camper/RV',
    ],
    'Others': [
      'Bicycle',
      'Quad Bike/ATV',
      'Golf Cart',
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Vehicle Details")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Vehicle Category Dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: "Vehicle Category",
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                dropdownColor: const Color.fromARGB(255, 255, 255, 255),
                items: _vehicleCategories.keys.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(
                      category,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                    _selectedVehicleType = null; // Reset vehicle type when category changes
                  });
                },
                isExpanded: true,
                icon: const Icon(Icons.category),
                style: const TextStyle(fontSize: 16, color: Colors.black),
                validator: (value) => value == null ? "Select a vehicle category" : null,
              ),
              const SizedBox(height: 16),
              
              // Vehicle Type Dropdown (shown only when category is selected)
              if (_selectedCategory != null)
                DropdownButtonFormField<String>(
                  value: _selectedVehicleType,
                  decoration: InputDecoration(
                    labelText: "Select ${_selectedCategory} Type",
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  dropdownColor: Colors.white,
                  items: _vehicleCategories[_selectedCategory]!.map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(
                        type,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedVehicleType = newValue;
                    });
                  },
                  isExpanded: true,
                  icon: const Icon(Icons.directions_car),
                  style: const TextStyle(fontSize: 16, color: Colors.black),
                  validator: (value) => value == null ? "Select a vehicle type" : null,
                ),
              if (_selectedCategory != null)
                const SizedBox(height: 16),
              
              // SUV Category Dropdown (shown only when SUV is selected)
              if (_selectedVehicleType == 'SUV (Sport Utility Vehicle)')
                Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedSUVCategory,
                      decoration: const InputDecoration(
                        labelText: "SUV Category",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      dropdownColor: Colors.white,
                      items: _suvCategories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(
                            category,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedSUVCategory = newValue;
                        });
                      },
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down),
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                      validator: (value) => value == null ? "Select SUV category" : null,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),

            
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate() && 
                      _selectedCategory != null && 
                      _selectedVehicleType != null &&
                      (_selectedVehicleType != 'SUV (Sport Utility Vehicle)' || _selectedSUVCategory != null)) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const DashboardScreen()),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _selectedVehicleType == 'SUV (Sport Utility Vehicle)' && _selectedSUVCategory == null
                              ? 'Please select vehicle category, type, and SUV category'
                              : 'Please select both vehicle category and type'
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 40),
                  child:
                      Text("Save & Continue", style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
