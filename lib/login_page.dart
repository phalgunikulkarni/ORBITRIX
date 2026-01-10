import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'signup_page.dart';
import 'vehicle_info_page.dart';
import 'bluetooth_helper.dart';
import 'services/authentication_service.dart';
import 'services/storage_service.dart';
import 'dashboard_screen_google_maps.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _loginIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _loginIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Validate credentials against saved data
    final result = await AuthenticationService.login(
      _loginIdController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (!result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    // Check if vehicle info exists
    final vehicleInfo = await StorageService.getVehicleInfo();
    if (vehicleInfo == null) {
      // No vehicle info yet, go to vehicle info page
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const VehicleInfoPage()),
      );
      return;
    }

    // Vehicle info exists, ask to enable Bluetooth & GPS
    if (!mounted) return;
    final navigator = Navigator.of(context);

    final proceed = await showDialog<bool>(
      context: navigator.context,
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

    if (proceed != true) {
      if (!mounted) return;
      // Still proceed to dashboard even if user says no
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => DashboardScreenGoogleMaps()),
      );
      return;
    }

    // Enable Bluetooth (requests permissions too)
    final btOk = await enableBluetooth(navigator);

    // Check location permission / service for GPS
    final locStatus = await Permission.locationWhenInUse.request();
    if (!locStatus.isGranted && mounted) {
      await showDialog<void>(
        context: navigator.context,
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

    // Proceed to dashboard
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) => DashboardScreenGoogleMaps()),
    );
  }

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
                    onPressed: _isLoading ? null : _handleLogin,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12.0, horizontal: 40),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text("Login",
                              style: TextStyle(fontSize: 18)),
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
