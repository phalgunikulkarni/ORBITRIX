import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'signup_page.dart';
import 'vehicle_info_page.dart';
import 'bluetooth_helper.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _loginIdController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _loginIdController,
                    decoration: const InputDecoration(
                      labelText: "Login ID",
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) =>
                        value!.isEmpty ? "Enter your Login ID" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: "Password",
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: (value) =>
                        value!.isEmpty ? "Enter your password" : null,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;

                      // Ask user to enable Bluetooth & GPS after login
                      final proceed = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text('Enable Bluetooth & GPS'),
                          content: const Text(
                              'This app needs Bluetooth and GPS enabled to work properly. Would you like to enable them now?'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.of(c).pop(false),
                                child: const Text('No')),
                            TextButton(
                                onPressed: () => Navigator.of(c).pop(true),
                                child: const Text('Yes')),
                          ],
                        ),
                      );

                      if (proceed != true) return;

                      // Enable Bluetooth (requests permissions too)
                      final btOk = await enableBluetooth(context);

                      // Check location permission / service for GPS
                      final locStatus = await Permission.locationWhenInUse.request();
                      if (!locStatus.isGranted) {
                        await showDialog<void>(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: const Text('Location permission required'),
                            content: const Text(
                                'Location permission is required for GPS functionality. Please grant it in app settings.'),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.of(c).pop(),
                                  child: const Text('OK')),
                            ],
                          ),
                        );
                      }

                      // If Bluetooth and location are OK, proceed
                      if (btOk && locStatus.isGranted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const VehicleInfoPage()),
                        );
                      }
                    },
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 12.0, horizontal: 40),
                      child: Text("Login", style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don't have an account?"),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SignupPage()),
                    );
                  },
                  child: const Text(
                    "Sign Up",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
