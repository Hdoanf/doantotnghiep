# 🏥 HealthPulse VN - Đồ án tốt nghiệp của Doanchim

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Firebase-039BE5?style=for-the-badge&logo=Firebase&logoColor=white" alt="Firebase">
  <img src="https://img.shields.io/badge/Google%20Gemini-8E75B2?style=for-the-badge&logo=googlegemini&logoColor=white" alt="Gemini">
  <img src="https://img.shields.io/badge/ESP32--C3-E7352C?style=for-the-badge&logo=espressif&logoColor=white" alt="ESP32">
</p>

**HealthPulse VN** là ứng dụng di động tích hợp **AI** và **IoT** giúp quản lý sức khỏe cá nhân chủ động. Đây là dự án cá nhân thuộc đồ án tốt nghiệp của **Doanchim**.

---

## ✨ Tính năng chính

- **AI Health:** Phân tích chỉ số, tư vấn sức khỏe qua Chat (Gemini AI) và quét phiếu xét nghiệm (OCR).
- **IoT Integration:** Kết nối BLE với ESP32-C3 để đo nhịp tim và SpO2 thời gian thực.
- **Monitoring:** Theo dõi biểu đồ sinh tồn và quản lý hồ sơ sức khỏe trên Cloud.

## 🛠 Công nghệ sử dụng

- **Frontend:** Flutter (Dart), Provider, fl_chart.
- **Backend:** Firebase (Auth, Firestore).
- **AI Engine:** Google Gemini AI, ML Kit OCR.
- **Hardware:** ESP32-C3, Cảm biến MAX30102 (BLE).

## 🚀 Cài đặt nhanh

1. **Flutter:**
   ```bash
   flutter pub get
   flutter run
   ```
2. **Hardware:** Code nạp cho ESP32-C3 nằm trong thư mục `health_esp32/`.

## 📂 Cấu trúc dự án
- `lib/services/`: Logic xử lý BLE, Firebase, AI.
- `lib/screens/`: Giao diện các chức năng chính.
- `health_esp32/`: Mã nguồn cho thiết bị đo.

---
**Phát triển bởi Doanchim**
