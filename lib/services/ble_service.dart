import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

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

  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      debugPrint("BLE: Requesting permissions for Android...");
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
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
    
    // Wait for Bluetooth to be on
    debugPrint("BLE: Waiting for adapter state ON...");
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
    await device.connect();
    connectedDevice = device;
    
    device.connectionState.listen((state) {
      _connectionStateController.add(state);
      if (state == BluetoothConnectionState.disconnected) {
        connectedDevice = null;
        dataCharacteristic = null;
      }
    });

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

  void _parseData(List<int> value) {
    try {
      String decoded = utf8.decode(value);
      // Data might be JSON or CSV. Let's try JSON first as per plan.
      if (decoded.startsWith('{')) {
        Map<String, dynamic> data = jsonDecode(decoded);
        _dataStreamController.add(data);
      } else {
        // Fallback for CSV: bpm,spo2,raw
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
      // Ignore parsing errors for malformed packets
    }
  }

  Future<void> disconnect() async {
    if (connectedDevice != null) {
      await connectedDevice!.disconnect();
    }
  }
}
