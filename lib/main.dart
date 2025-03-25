import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bluetooth Scanner',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const BluetoothScreen(),
    );
  }
}

class BluetoothScreen extends StatefulWidget {
  const BluetoothScreen({super.key});

  @override
  _BluetoothScreenState createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  final flutterBlue = FlutterBluePlus(); // ✅ FIXED
  List<BluetoothDevice> scannedDevices = [];

  @override
  void initState() {
    super.initState();
    requestPermissions();
  }

  /// Request Bluetooth Permissions (Android 12+)
  Future<void> requestPermissions() async {
    await Permission.bluetooth.request();
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    await Permission.location.request();
  }

  /// Start scanning for Bluetooth devices
  void startScan() {
    scannedDevices.clear();
    setState(() {}); // Refresh UI

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        scannedDevices = results.map((r) => r.device).toList();
      });

      // Try fetching names dynamically if they are initially empty
      for (var device in scannedDevices) {
        if (device.platformName.isEmpty) {
          device.discoverServices().then((_) {
            setState(() {}); // Refresh UI if name appears later
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bluetooth Scanner")),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: startScan,
            child: const Text("Scan for Devices"),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: scannedDevices.length,
              itemBuilder: (context, index) {
                final device = scannedDevices[index];
                return ListTile(
                  title: Text(
                    device.platformName.isNotEmpty
                        ? device.platformName
                        : "Fetching name...",
                  ),
                  subtitle: Text(device.remoteId.toString()),
                  trailing: ElevatedButton(
                    onPressed: () {
                      debugPrint("Connecting to ${device.platformName}");
                      device.connect();
                    },
                    child: const Text("Connect"),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
