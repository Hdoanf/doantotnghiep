# 🏥 HealthPulse VN - Giải pháp Theo dõi Sức khỏe Thông minh

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Firebase-039BE5?style=for-the-badge&logo=Firebase&logoColor=white" alt="Firebase">
  <img src="https://img.shields.io/badge/Google%20Gemini-8E75B2?style=for-the-badge&logo=googlegemini&logoColor=white" alt="Gemini">
  <img src="https://img.shields.io/badge/ESP32--C3-E7352C?style=for-the-badge&logo=espressif&logoColor=white" alt="ESP32">
</p>

**HealthPulse VN** là ứng dụng di động tiên phong tích hợp **AI (Trí tuệ nhân tạo)** và **IoT (Internet vạn vật)** để giúp người dùng quản lý sức khỏe cá nhân một cách chủ động, chính xác và dễ dàng nhất.

---

## ✨ Tính năng nổi bật

### 🧠 Trí tuệ nhân tạo (AI)
- **AI OCR Lab Scanner:** Tự động trích xuất dữ liệu từ phiếu kết quả xét nghiệm máu chỉ bằng một tấm ảnh chụp (ML Kit).
- **Gemini Health Insights:** Phân tích dữ liệu sức khỏe tổng thể, đưa ra cảnh báo và lời khuyên y tế cá nhân hóa thông qua mô hình ngôn ngữ lớn của Google.
- **AI Assistant:** Chatbot hỗ trợ 24/7 giải đáp mọi thắc mắc về y tế dựa trên dữ liệu lịch sử của chính người dùng.

### ⌚ Kết nối phần cứng (IoT - BLE)
- **Real-time Heart Rate:** Kết nối trực tiếp với module **ESP32-C3** và cảm biến **MAX30102**.
- **Live PPG Graph:** Theo dõi dạng sóng xung nhịp tim trực quan ngay trên điện thoại.
- **Auto-Sync:** Tự động ghi nhớ và kết nối lại thiết bị đo mỗi khi mở ứng dụng.

### 📊 Quản lý dữ liệu
- **Dashboard Bento:** Giao diện thẻ hiện đại, tóm tắt nhanh tình trạng Huyết áp, Nhịp tim, Đường huyết.
- **Health Trends:** Biểu đồ hóa các chỉ số theo thời gian để theo dõi diễn biến sức khỏe dài hạn.
- **Cloud Secure:** Lưu trữ dữ liệu an toàn trên nền tảng Google Firebase.

---

## 🛠 Công nghệ sử dụng

| Lớp (Layer) | Công nghệ |
| :--- | :--- |
| **Mobile App** | Flutter (Dart 3), Provider, fl_chart |
| **Backend** | Firebase Auth, Firestore |
| **AI Engine** | Google Gemini AI, Google ML Kit (OCR) |
| **Hardware** | ESP32-C3 Super Mini, C++, BLE (Bluetooth Low Energy) |
| **Sensors** | MAX30102 (Heart Rate & SpO2) |

---

## 🚀 Bắt đầu nhanh

### 1. Dành cho ứng dụng Flutter
1. Cài đặt Flutter SDK (v3.10.7+).
2. Clone project và chạy lệnh cài đặt:
   ```bash
   flutter pub get
   ```
3. Cấu hình file `google-services.json` từ Firebase Console vào thư mục `android/app/`.
4. Chạy ứng dụng:
   ```bash
   flutter run
   ```

### 2. Dành cho phần cứng (ESP32)
Chúng tôi cung cấp script nạp code tự động cho Linux:
1. Cắm ESP32-C3 vào cổng USB.
2. Cấp quyền truy cập: `sudo chmod 666 /dev/ttyACM0`
3. Chạy script:
   ```bash
   ./flash_esp32.sh
   ```

---

## 📂 Cấu trúc thư mục

```text
lib/
├── config/     # Giao diện (Theme) và hằng số sức khỏe
├── models/     # Mô hình dữ liệu (HealthRecord, User)
├── services/   # Bộ não logic (BLE, Firestore, Gemini, OCR)
├── screens/    # Các màn hình tính năng (Home, Scan, AI, Vitals)
└── widgets/    # Các thành phần UI dùng chung
health_esp32/   # Mã nguồn C++ cho module ESP32
```

---

## 🗺 Lộ trình phát triển

- [x] Tích hợp kết nối BLE với ESP32-C3.
- [x] Đồ thị nhịp tim thời gian thực.
- [x] AI tư vấn sức khỏe qua Chat.
- [ ] Giai đoạn 2: Nhắc nhở uống thuốc thông minh.
- [ ] Giai đoạn 3: Phân tích chế độ dinh dưỡng qua hình ảnh bữa ăn.

---

## 📄 Bản quyền & Đóng góp
Dự án được phát triển bởi **HealthPulse VN Team**. Mọi đóng góp vui lòng gửi qua phần **Issues** của Repository này.

---
<p align="center">
  Made with ❤️ for a healthier Vietnam.
</p>
