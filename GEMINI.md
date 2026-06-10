# HealthPulse VN - Ghi chú cá nhân

## 1. Kết nối BLE (ESP32-C3)
- **Service UUID**: `19b10000-e8f2-537e-4f6c-d104768a1214`
- **Characteristic UUID**: `19b10001-e8f2-537e-4f6c-d104768a1214` (Notify)
- **Data**: JSON `{"bpm": double, "spo2": double, "raw": double}` hoặc CSV `bpm,spo2,raw`.
- **Logic**: Quản lý tại `ble_service.dart`, hiển thị tại `live_vitals_screen.dart`.

## 2. Công nghệ sử dụng
- **State**: Provider.
- **Backend**: Firebase (Firestore, Auth).
- **Chart**: fl_chart.
- **AI**: Gemini API / OpenRouter.

## 3. Cấu trúc chính
- `lib/services/`: Logic BLE, Firestore, OCR, Gemini.
- `lib/screens/`: Giao diện chức năng.
- `lib/models/`: Định dạng dữ liệu (User, Record).

## 4. Lệnh nhanh
- `flutter pub get`
- `flutter analyze`
- `flutter run`
