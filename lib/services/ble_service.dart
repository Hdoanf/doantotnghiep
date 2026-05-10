import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:shared_preferences/shared_preferences.dart';

class BleService {
  static final BleService _instance = BleService._internal();
  factory BleService() => _instance;
  BleService._internal();

  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? dataCharacteristic;

  final _dataStreamController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get dataStream => _dataStreamController.stream;

  final _connectionStateController = StreamController<BluetoothConnectionState>.broadcast();
  Stream<BluetoothConnectionState> get connectionState => _connectionStateController.stream;

  static const String serviceUuid = "19b10000-e8f2-537e-4f6c-d104768a1214";
  static const String characteristicUuid = "19b10001-e8f2-537e-4f6c-d104768a1214";
  static const String _prefDeviceKey = "last_connected_device_id";

  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      debugPrint("BLE: Requesting permissions for Android...");
      Map<ph.Permission, ph.PermissionStatus> statuses = await [
        ph.Permission.bluetoothScan,
        ph.Permission.bluetoothConnect,
        ph.Permission.location,
      ].request();
      debugPrint("BLE: Permission statuses: $statuses");
      return statuses.values.every((status) => status.isGranted);
    }
    return true;
  }

  Future<void> startScan() async {
    debugPrint("BLE: Starting scan...");
    if (await FlutterBluePlus.isSupported == false) {
        debugPrint("BLE: Bluetooth not supported");
        return;
    }
    
    await FlutterBluePlus.adapterState.where((s) => s == BluetoothAdapterState.on).first;
    debugPrint("BLE: Adapter is ON");

    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 15),
    );
    debugPrint("BLE: Scan initiated");
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  Future<void> connect(BluetoothDevice device) async {
    debugPrint("BLE: Connecting to ${device.remoteId}...");
    await device.connect();
    connectedDevice = device;
    
    // Save device ID for auto-connect
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefDeviceKey, device.remoteId.toString());

    device.connectionState.listen((state) {
      _connectionStateController.add(state);
      if (state == BluetoothConnectionState.disconnected) {
        connectedDevice = null;
        dataCharacteristic = null;
      }
    });

    await _discoverAndSubscribe(device);
  }

  Future<void> _discoverAndSubscribe(BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();
    for (var service in services) {
      if (service.uuid.toString().toLowerCase() == serviceUuid.toLowerCase()) {
        for (var char in service.characteristics) {
          if (char.uuid.toString().toLowerCase() == characteristicUuid.toLowerCase()) {
            dataCharacteristic = char;
            await char.setNotifyValue(true);
            char.onValueReceived.listen((value) {
              _parseData(value);
            });
          }
        }
      }
    }
  }

  Future<void> autoConnect() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString(_prefDeviceKey);
    
    if (savedId == null || connectedDevice != null) return;
    
    debugPrint("BLE: Attempting auto-connect to $savedId");

    // Request permissions first
    bool hasPermission = await requestPermissions();
    if (!hasPermission) return;
    
    // Check if already system connected
    List<BluetoothDevice> systemDevices = await FlutterBluePlus.systemDevices([]);
    for (var device in systemDevices) {
      if (device.remoteId.toString() == savedId) {
        await connect(device);
        return;
      }
    }

    // Try scanning for it
    StreamSubscription? subscription;
    subscription = FlutterBluePlus.scanResults.listen((results) async {
      for (ScanResult r in results) {
        if (r.device.remoteId.toString() == savedId) {
          debugPrint("BLE: Found saved device, connecting...");
          subscription?.cancel();
          await FlutterBluePlus.stopScan();
          await connect(r.device);
          break;
        }
      }
    });

    await startScan();
    // Stop auto-scan after 10s if not found
    Future.delayed(const Duration(seconds: 10), () {
      subscription?.cancel();
    });
  }

  void _parseData(List<int> value) {
    try {
      String decoded = utf8.decode(value);
      if (decoded.startsWith('{')) {
        Map<String, dynamic> data = jsonDecode(decoded);
        _dataStreamController.add(data);
      } else {
        List<String> parts = decoded.split(',');
        if (parts.length >= 3) {
          _dataStreamController.add({
            'bpm': double.tryParse(parts[0]) ?? 0.0,
            'spo2': double.tryParse(parts[1]) ?? 0.0,
            'raw': double.tryParse(parts[2]) ?? 0.0,
          });
        }
      }
    } catch (e) {
      // Ignore errors
    }
  }

  Future<void> disconnect() async {
    if (connectedDevice != null) {
      await connectedDevice!.disconnect();
    }
  }

  Future<void> forgetDevice() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefDeviceKey);
    await disconnect();
  }
}
