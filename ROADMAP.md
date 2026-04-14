# Kế hoạch Phát triển & Nâng cấp Tương lai (Roadmap) - HF Health

Dưới đây là định hướng phát triển để biến **HF Health** từ một ứng dụng theo dõi cá nhân cơ bản thành một hệ sinh thái chăm sóc sức khỏe toàn diện, thông minh và có khả năng thương mại hóa.

---

## 🚀 Giai đoạn 1: Tối ưu hóa Trải nghiệm & Ổn định (Short-term)
*Tập trung vào việc làm cho ứng dụng hiện tại mượt mà, đẹp mắt và không có lỗi.*

1. **Hoàn thiện UI/UX & Animations**
   - Áp dụng các hiệu ứng chuyển cảnh mượt mà (Hero animations) giữa các màn hình (ví dụ: từ Lịch sử sang Chi tiết).
   - Thêm trạng thái Loading Skeleton (Shimmer effect) khi chờ tải dữ liệu từ Firestore thay vì chỉ dùng vòng quay (CircularProgressIndicator).
   - Cải thiện Dark Mode: Đảm bảo độ tương phản màu sắc chuẩn WCAG cho chế độ tối.

2. **Cải thiện OCR & AI Parsing**
   - Thêm tính năng Crop ảnh (cắt vùng cần quét) trước khi đưa vào ML Kit để tăng độ chính xác.
   - Huấn luyện/Cung cấp thêm ngữ cảnh cho Gemini để nhận diện tốt hơn các form giấy khám sức khỏe đặc thù của các bệnh viện lớn tại Việt Nam (Vinmec, Chợ Rẫy, Bạch Mai...).

3. **Quản lý State mạnh mẽ hơn**
   - Hiện tại đang dùng `Provider` cơ bản. Cân nhắc chuyển sang `Riverpod` hoặc `Bloc` để quản lý luồng dữ liệu phức tạp hơn khi ứng dụng lớn lên.

---

## 🌟 Giai đoạn 2: Tích hợp Hệ sinh thái & Tiện ích (Mid-term)
*Kết nối app với các thiết bị ngoại vi và cung cấp nhiều công cụ hữu ích hơn.*

1. **Tích hợp Apple Health & Google Fit**
   - Sử dụng package `health` để tự động đồng bộ số bước chân, quãng đường, nhịp tim, giấc ngủ từ smartwatch (Apple Watch, Garmin, v.v.).
   - Giảm thiểu việc người dùng phải nhập tay các chỉ số sinh tồn cơ bản.

2. **Hệ thống Nhắc nhở & Báo thức (Notifications)**
   - Nhắc lịch uống thuốc hàng ngày.
   - Nhắc lịch tái khám dựa trên ngày khám gần nhất và lời khuyên của AI.
   - Cảnh báo (Push Notification) nếu chỉ số sức khỏe liên tục ở mức báo động (ví dụ: Huyết áp cao nhiều ngày liền).

3. **Gamification (Game hóa)**
   - Hệ thống huy hiệu/điểm thưởng khi người dùng đạt mục tiêu sức khỏe (ví dụ: "7 ngày liên tục giữ đường huyết ổn định").
   - Mục tiêu hàng ngày: Uống đủ nước, đi đủ bước chân.

---

## 🔥 Giai đoạn 3: Y tế Chuyên sâu & Cá nhân hóa AI (Long-term)
*Biến app thành một "Bác sĩ gia đình AI" thực thụ.*

1. **Phân tích Xu hướng Nâng cao (Advanced Analytics)**
   - Cung cấp biểu đồ so sánh nhiều chỉ số cùng lúc (ví dụ: Tương quan giữa Cân nặng và Huyết áp).
   - Xuất file PDF Báo cáo sức khỏe tổng quát định kỳ (Tháng/Quý) để người dùng gửi cho bác sĩ thật.

2. **Tính năng Dinh dưỡng & Khẩu phần ăn**
   - Tích hợp AI để phân tích bữa ăn qua camera (chụp ảnh mâm cơm, AI tính toán Calo, Tinh bột, Đạm).
   - Đề xuất thực đơn hàng ngày (Meal Plan) dựa trên tình trạng bệnh lý (ví dụ: Thực đơn cho người tiểu đường).

3. **Đa tài khoản (Family Mode)**
   - Cho phép một người dùng tạo nhiều hồ sơ (ví dụ: Quản lý sức khỏe cho bố mẹ già, con cái) trên cùng một tài khoản đăng nhập.

4. **Tích hợp Telemedicine (Khám bệnh từ xa)**
   - (Mục tiêu thương mại hóa): Liên kết với các phòng khám, cho phép người dùng đặt lịch khám hoặc gọi video trực tiếp với bác sĩ ngay trên app.
   - Chia sẻ an toàn lịch sử sức khỏe từ app trực tiếp cho bác sĩ.

---

## 🔒 Bảo mật & Riêng tư (Security)
*Đây là yếu tố sống còn với ứng dụng y tế.*

- **Mã hóa dữ liệu (Encryption):** Đảm bảo dữ liệu nhạy cảm lưu trên Firestore phải được mã hóa đầu cuối.
- **Xác thực sinh trắc học:** Thêm tính năng đăng nhập bằng FaceID / TouchID / Vân tay.
- **Quyền riêng tư (Privacy Policy):** Cung cấp chính sách rõ ràng về việc sử dụng dữ liệu để huấn luyện AI. Tuân thủ các tiêu chuẩn y tế (như HIPAA nếu muốn mở rộng ra quốc tế).
