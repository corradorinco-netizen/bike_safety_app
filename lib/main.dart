import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:sensors_plus/sensors_plus.dart';

void main() {
  runApp(const BikeSafetyApp());
}

class BikeSafetyApp extends StatelessWidget {
  const BikeSafetyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bike Safety Tracking',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const RoleSelectionScreen(),
    );
  }
}

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bike Safety Tracker'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.directions_bike, size: 28),
              label: const Text('SONO IL CICLISTA', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MonitorScreen(isRider: true),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.remove_red_eye, size: 28),
              label: const Text('SONO IL CONTROLLORE', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MonitorScreen(isRider: false),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class MonitorScreen extends StatefulWidget {
  final bool isRider;
  const MonitorScreen({super.key, required this.isRider});

  @override
  State<MonitorScreen> createState() => _MonitorScreenState();
}

class _MonitorScreenState extends State<MonitorScreen> {
  final Battery _battery = Battery();
  int _batteryLevel = 100;
  String? _alertMessage;
  
  Completer<GoogleMapController> _mapController = Completer();
  StreamSubscription<UserAccelerometerEvent>? _accelSubscription;

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(41.9028, 12.4964), // Roma
    zoom: 15.0,
  );

  @override
  void initState() {
    super.initState();
    _initMonitoring();
  }

  void _initMonitoring() async {
    // Lettura batteria
    final level = await _battery.batteryLevel;
    setState(() {
      _batteryLevel = level;
    });

    _battery.onBatteryStateChanged.listen((BatteryState state) async {
      final currentLevel = await _battery.batteryLevel;
      setState(() {
        _batteryLevel = currentLevel;
      });
    });

    // Rilevamento caduta (Accelerometro)
    if (widget.isRider) {
      _accelSubscription = userAccelerometerEvents.listen((UserAccelerometerEvent event) {
        double gForce = (event.x * event.x + event.y * event.y + event.z * event.z);
        if (gForce > 250) { // Soglia d'impatto/caduta
          setState(() {
            _alertMessage = "ATTENZIONE: Rilevata caduta del ciclista!";
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _accelSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isRider ? 'Tracciamento Ciclista' : 'Pannello Controllore'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialPosition,
            onMapCreated: (GoogleMapController controller) {
              _mapController.complete(controller);
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
          Positioned(
            top: 16,
            right: 16,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.battery_charging_full, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      '$_batteryLevel%',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_alertMessage != null)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: Card(
                color: Colors.redAccent,
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.white, size: 36),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _alertMessage!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}