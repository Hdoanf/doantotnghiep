import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../config/app_theme.dart';
import '../../services/ble_service.dart';
import '../input/live_vitals_screen.dart';

class BleDeviceScanScreen extends StatefulWidget {
  const BleDeviceScanScreen({super.key});

  @override
  State<BleDeviceScanScreen> createState() => _BleDeviceScanScreenState();
}

class _BleDeviceScanScreenState extends State<BleDeviceScanScreen> {
  final BleService _bleService = BleService();
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  void _startScan() async {
    debugPrint("UI: Starting scan process...");
    
    // Check if Location Service is enabled (Crucial for Android BLE)
    bool isLocationEnabled = await Permission.location.serviceStatus.isEnabled;
    debugPrint("UI: Location services enabled: $isLocationEnabled");
    if (!isLocationEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng bật Vị trí (GPS) trên điện thoại để tìm thiết bị.')),
        );
      }
    }

    debugPrint("UI: Requesting permissions...");
    bool hasPermission = await _bleService.requestPermissions();
    debugPrint("UI: Permissions granted: $hasPermission");
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cần quyền Bluetooth và Vị trí để quét thiết bị.')),
        );
      }
      return;
    }

    setState(() => _isScanning = true);
    try {
      debugPrint("UI: Calling service.startScan()...");
      await _bleService.startScan();
    } catch (e) {
      debugPrint("UI: Scan error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi quét: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  void _connectToDevice(BluetoothDevice device) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await _bleService.connect(device);
      if (mounted) {
        Navigator.pop(context); // Close loading
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LiveVitalsScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi kết nối: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Tìm thiết bị đo',
          style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.secondaryTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isScanning)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh, color: AppTheme.primaryColor),
              onPressed: _startScan,
            ),
        ],
      ),
      body: StreamBuilder<List<ScanResult>>(
        stream: FlutterBluePlus.scanResults,
        initialData: const [],
        builder: (context, snapshot) {
          final results = snapshot.data ?? [];
          // Filter out devices with no name if desired, or just show all
          if (results.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bluetooth_searching, size: 64, color: AppTheme.mutedTextColor),
                  const SizedBox(height: 16),
                  const Text(
                    'Không tìm thấy thiết bị nào.\nHãy đảm bảo ESP32 đã bật Bluetooth.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.secondaryTextColor),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _startScan,
                    child: const Text('Thử quét lại'),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: results.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final device = results[index].device;
              final name = device.platformName.isEmpty ? 'Thiết bị không xác định' : device.platformName;
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                    child: const Icon(Icons.bluetooth, color: AppTheme.primaryColor),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textColor),
                  ),
                  subtitle: Text(
                    device.remoteId.toString(),
                    style: const TextStyle(fontSize: 12, color: AppTheme.mutedTextColor),
                  ),
                  trailing: ElevatedButton(
                    onPressed: () => _connectToDevice(device),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Kết nối'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
