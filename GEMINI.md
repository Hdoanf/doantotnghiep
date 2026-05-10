# Dự án HealthPulse VN - Tài liệu Hướng dẫn & Quy ước

## 1. Kiến trúc Tích hợp Thiết bị Ngoại vi (BLE)
Dự án sử dụng Bluetooth Low Energy (BLE) để kết nối với các thiết bị đo sức khỏe (đặc biệt là ESP32-C3).

### Thành phần chính:
- **`lib/services/ble_service.dart`**: Singleton quản lý toàn bộ vòng đời kết nối BLE, quét thiết bị và giải mã dữ liệu.
- **`lib/screens/scan/ble_device_scan_screen.dart`**: Giao diện quét và chọn thiết bị.
- **`lib/screens/input/live_vitals_screen.dart`**: Hiển thị dữ liệu trực tiếp (Live Numbers & Live Graph) và lưu vào Firestore.

### Quy trình kết nối (Workflow):
1. Người dùng vào màn hình "Nhập Sinh Tồn".
2. Chọn "Kết nối thiết bị đo (Bluetooth)".
3. Cấp quyền (Bluetooth/Vị trí) và chọn ESP32 từ danh sách.
4. Theo dõi chỉ số trực tiếp và nhấn "Lưu" để ghi lại dữ liệu.

### Giao thức dữ liệu (Data Protocol):
- **Service UUID**: `19b10000-e8f2-537e-4f6c-d104768a1214`
- **Characteristic UUID**: `19b10001-e8f2-537e-4f6c-d104768a1214` (Notify)
- **Định dạng Payload**: JSON hoặc CSV.
    - JSON: `{"bpm": double, "spo2": double, "raw": double}`
    - CSV: `bpm,spo2,raw`

## 2. Quy ước Phát triển
- **Quản lý trạng thái**: Sử dụng `Provider`.
- **Cơ sở dữ liệu**: Firebase Firestore thông qua `FirestoreService`.
- **UI Components**: Tuân thủ bảng màu và font chữ định nghĩa trong `lib/config/app_theme.dart`.
- **Đồ thị**: Sử dụng thư viện `fl_chart`.

## 3. Các lệnh thường dùng
- `flutter pub get`: Cập nhật thư viện.
- `flutter analyze`: Kiểm tra lỗi tĩnh.
- `flutter run`: Chạy ứng dụng.
