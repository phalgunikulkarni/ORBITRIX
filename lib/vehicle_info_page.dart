import 'package:flutter/material.dart';
import 'dashboard_screen.dart';

class VehicleInfoPage extends StatefulWidget {
  const VehicleInfoPage({super.key});

  @override
  State<VehicleInfoPage> createState() => _VehicleInfoPageState();
}

class _VehicleInfoPageState extends State<VehicleInfoPage> {
  final _formKey = GlobalKey<FormState>();
  String _vehicleType = "Car";
  final _vehicleNumberController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();

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
              DropdownButtonFormField<String>(
                initialValue: _vehicleType,
                decoration: const InputDecoration(labelText: "Vehicle Type"),
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem<String>(
                    value: "Car",
                    child: Text("Car"),
                  ),
                  DropdownMenuItem<String>(
                    value: "Bike",
                    child: Text("Bike"),
                  ),
                ],
                onChanged: (val) => setState(() => _vehicleType = val!),
              ),
              TextFormField(
                controller: _vehicleNumberController,
                decoration: const InputDecoration(labelText: "Vehicle Number"),
                validator: (value) =>
                    value!.isEmpty ? "Enter vehicle number" : null,
              ),
              TextFormField(
                controller: _modelController,
                decoration: const InputDecoration(labelText: "Model"),
              ),
              TextFormField(
                controller: _yearController,
                decoration: const InputDecoration(labelText: "Year"),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const DashboardScreen()),
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
