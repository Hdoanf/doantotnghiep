# HF Health - Ứng dụng Theo dõi Sức khỏe Thông minh

HF Health là một ứng dụng di động được xây dựng bằng Flutter, giúp người dùng theo dõi và quản lý sức khỏe cá nhân một cách toàn diện. Ứng dụng tích hợp công nghệ AI tiên tiến (Google Gemini) để phân tích dữ liệu và Google ML Kit (OCR) để tự động trích xuất thông tin từ các phiếu kết quả xét nghiệm.

## 🌟 Tính năng chính

- **Theo dõi chỉ số sức khỏe:** Nhập và theo dõi các chỉ số sinh tồn (huyết áp, nhịp tim), chỉ số cơ thể (BMI, cân nặng) và kết quả xét nghiệm máu.
- **AI OCR (Quét kết quả xét nghiệm):** Sử dụng camera để chụp và tự động trích xuất dữ liệu từ các phiếu kết quả xét nghiệm in giấy, giúp tiết kiệm thời gian nhập liệu.
- **Phân tích sức khỏe bằng AI:** Tích hợp Google Gemini AI để đưa ra các nhận xét, lời khuyên và giải thích các chỉ số sức khỏe một cách dễ hiểu.
- **Trò chuyện với AI (AI Chat):** Hỗ trợ giải đáp các thắc mắc về sức khỏe dựa trên ngữ cảnh dữ liệu cá nhân của người dùng.
- **Dashboard trực quan:** Biểu diễn xu hướng sức khỏe qua các biểu đồ (fl_chart) và thẻ tóm tắt trạng thái.
- **Quản lý lịch sử:** Lưu trữ và quản lý dòng thời gian các bản ghi sức khỏe một cách khoa học.
- **Hỗ trợ tiếng Việt:** Giao diện và nội dung được tối ưu hóa hoàn toàn cho người dùng Việt Nam.

## 🛠 Tech Stack

- **Ngôn ngữ:** Dart (3.10.7+)
- **Framework:** Flutter
- **Thiết kế:** Material Design 3
- **Quản lý trạng thái:** Provider
- **Backend:** Firebase (Authentication, Cloud Firestore)
- **AI Engine:** 
  - Google Generative AI (Gemini Pro) cho phân tích và Chatbot.
  - Google ML Kit cho nhận diện văn bản (OCR).
- **Đồ họa:** fl_chart
- **Công cụ khác:** image_picker, camera, uuid, intl.

## 📋 Yêu cầu hệ thống

Trước khi bắt đầu, hãy đảm bảo bạn đã cài đặt:
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.10.7 trở lên)
- [Dart SDK](https://dart.dev/get-started/sdk/install)
- [Android Studio](https://developer.android.com/studio) hoặc [VS Code](https://code.visualstudio.com/)
- Một tài khoản [Firebase](https://console.firebase.google.com/)
- API Key của [Google AI Studio (Gemini)](https://aistudio.google.com/app/apikey)

## 🚀 Hướng dẫn cài đặt

### 1. Clone Repository
```bash
git clone https://github.com/user/hf_health.git
cd hf_health
```

### 2. Cài đặt các Package
```bash
flutter pub get
```

### 3. Cấu hình Firebase
1. Tạo một project mới trên [Firebase Console](https://console.firebase.google.com/).
2. Thêm ứng dụng Android và iOS vào project.
3. Tải tệp `google-services.json` (cho Android) và `GoogleService-Info.plist` (cho iOS) về máy.
4. Đặt `google-services.json` vào thư mục `android/app/`.
5. Đặt `GoogleService-Info.plist` vào thư mục `ios/Runner/`.
6. Bật **Email/Password Authentication** và **Cloud Firestore** trong Firebase Console.

### 4. Cấu hình API Gemini
Tạo một tệp cấu hình hoặc thiết lập biến môi trường cho Gemini API Key trong ứng dụng của bạn (thường được xử lý trong `GeminiService`).

### 5. Chạy ứng dụng
```bash
# Chạy trên thiết bị giả lập hoặc thiết bị thật
flutter run
```

## 🏗 Kiến trúc dự án

Dự án được tổ chức theo cấu trúc thư mục rõ ràng:

```
lib/
├── config/          # Cấu hình Theme, Constants (màu sắc, chỉ số sức khỏe)
├── models/          # Các Data Models (HealthRecord, UserModel, ChatMessage)
├── screens/         # Giao diện người dùng phân theo tính năng
│   ├── ai/          # Màn hình Chat AI
│   ├── auth/        # Login, Register
│   ├── history/     # Danh sách bản ghi, Chi tiết bản ghi
│   ├── home/        # Dashboard chính
│   ├── input/       # Nhập liệu thủ công (Máu, Vitals, Body)
│   ├── profile/     # Hồ sơ cá nhân
│   └── scan/        # Quét OCR
├── services/        # Logic nghiệp vụ (Auth, Firestore, Gemini, OCR)
├── widgets/         # Các thành phần giao diện dùng chung
└── app.dart         # Cấu hình Router và App chính
```

## 🗺 Lộ trình phát triển (Roadmap)

### Giai đoạn 1: Tối ưu hóa (Hiện tại)
- Hoàn thiện UI/UX với hiệu ứng Shimmer và Hero animations.
- Cải thiện độ chính xác của AI OCR cho các mẫu bệnh viện tại Việt Nam.

### Giai đoạn 2: Tích hợp Hệ sinh thái
- Đồng bộ dữ liệu với Apple Health và Google Fit.
- Hệ thống thông báo nhắc nhở uống thuốc và tái khám.
- Gamification (Hệ thống huy hiệu thành tích sức khỏe).

### Giai đoạn 3: Y tế chuyên sâu
- Phân tích xu hướng nâng cao và xuất báo cáo PDF.
- AI phân tích khẩu phần ăn qua hình ảnh.
- Chế độ quản lý sức khỏe cho gia đình (Family Mode).

## 📄 Giấy phép

Dự án này được phát triển cho mục đích học tập và thực tập. Vui lòng liên hệ với tác giả trước khi sử dụng cho mục đích thương mại.

---
© 2026 HF Health Team. Made with ❤️ for a healthier Vietnam.
