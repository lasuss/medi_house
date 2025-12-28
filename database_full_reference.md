# Tài Liệu Tham Khảo Đầy Đủ Cơ Sở Dữ Liệu MediHouse

Tài liệu này cung cấp tham chiếu kỹ thuật toàn diện cho tất cả các bảng trong cơ sở dữ liệu MediHouse.

## 1. Bảng: `users`
Người dùng đã xác thực và các tác nhân hệ thống.

| Cột | Kiểu | Mặc định | Nullable | Ghi chú |
| :--- | :--- | :--- | :--- | :--- |
| **id** | `uuid` | `gen_random_uuid()` | Không | **Khóa chính (PK)** |
| `name` | `text` | - | Có | |
| `email` | `text` | - | Có | **Duy nhất** |
| `phone` | `text` | - | Có | |
| `role` | `text` | - | Có | Ràng buộc: `['patient', 'doctor', 'pharmacy', 'admin']` |
| `avatar_url` | `text` | - | Có | |
| `created_at` | `timestamp` | `now()` | Có | |
| `address` | `text` | - | Có | |
| `national_id` | `text` | - | Có | |
| `dob` | `date` | - | Có | Ngày sinh |
| `gender` | `text` | - | Có | Giới tính |

---

## 2. Bảng: `records`
Hồ sơ lâm sàng chính cho các lần khám/tư vấn.

| Cột | Kiểu | Mặc định | Nullable | Ghi chú |
| :--- | :--- | :--- | :--- | :--- |
| **id** | `uuid` | `gen_random_uuid()` | Không | **PK** |
| `patient_id` | `uuid` | - | Có | FK -> `users.id` |
| `doctor_id` | `uuid` | - | Có | FK -> `users.id` |
| `symptoms` | `text` | - | Có | Triệu chứng |
| `diagnosis` | `text` | - | Có | Chẩn đoán |
| `notes` | `text` | - | Có | Ghi chú |
| `status` | `text` | `'Pending'` | Có | Pending (Chờ), Prescribed (Đã kê đơn), Completed (Hoàn thành) |
| `triage_data`| `jsonb` | - | Có | Lưu trữ bản chụp bệnh nhân (tên, tuổi,...) không đổi |
| `created_at` | `timestamp` | `now()` | Có | |
| `updated_at` | `timestamp` | `now()` | Có | |

---

## 3. Bảng: `appointments`
Thông tin lịch trình cho hồ sơ lâm sàng.

| Cột | Kiểu | Mặc định | Nullable | Ghi chú |
| :--- | :--- | :--- | :--- | :--- |
| **id** | `uuid` | `gen_random_uuid()` | Không | **PK** |
| `record_id` | `uuid` | - | Có | FK -> `records.id` |
| `patient_id` | `uuid` | - | Có | FK -> `users.id` |
| `doctor_id` | `uuid` | - | Có | FK -> `users.id` |
| `date` | `timestamp` | - | Có | Ngày/Giờ hẹn |
| `time_slot` | `text` | - | Có | v.v. "09:00" |
| `status` | `text` | - | Có | |
| `type` | `text` | `'General'` | Có | Loại dịch vụ hoặc danh mục |
| `notes` | `text` | - | Có | |
| `created_at` | `timestamp` | `now()` | Có | |

---

## 4. Bảng: `prescriptions`
Đơn thuốc y tế liên kết với một hồ sơ.

| Cột | Kiểu | Mặc định | Nullable | Ghi chú |
| :--- | :--- | :--- | :--- | :--- |
| **id** | `uuid` | `gen_random_uuid()` | Không | **PK** |
| `record_id` | `uuid` | - | Có | FK -> `records.id` |
| `doctor_id` | `uuid` | - | Có | FK -> `users.id` |
| `patient_id` | `uuid` | - | Có | FK -> `users.id` |
| `status` | `text` | `'Pending'` | Có | Pending (Chờ), Filled (Đã phát), Completed (Hoàn thành) |
| `created_at` | `timestamp` | `now()` | Có | |

---

## 5. Bảng: `prescription_items`
Các mục thuốc riêng lẻ trong một đơn thuốc.

| Cột | Kiểu | Mặc định | Nullable | Ghi chú |
| :--- | :--- | :--- | :--- | :--- |
| **id** | `uuid` | `gen_random_uuid()` | Không | **PK** |
| `prescription_id` | `uuid` | - | Có | FK -> `prescriptions.id` |
| `medicine_id` | `uuid` | - | Có | FK -> `medicines.id` |
| `quantity` | `integer` | - | Không | Số lượng |
| `instructions` | `text` | - | Có | Hướng dẫn sử dụng |
| `created_at` | `timestamp` | `now()` | Có | |

---

## 6. Bảng: `medicines`
Danh mục thuốc y tế.

| Cột | Kiểu | Mặc định | Nullable | Ghi chú |
| :--- | :--- | :--- | :--- | :--- |
| **id** | `uuid` | `gen_random_uuid()` | Không | **PK** |
| `name` | `text` | - | Không | Tên thuốc |
| `active_ingredient`| `text` | - | Có | Hoạt chất |
| `manufacturer` | `text` | - | Có | Nhà sản xuất |
| `unit` | `text` | - | Có | Đơn vị tính (v.v. Viên, Chai) |
| `price` | `numeric` | - | Có | Giá |
| `description` | `text` | - | Có | Mô tả |
| `image_url` | `text` | - | Có | |
| `created_at` | `timestamp` | `now()` | Có | |

---

## 7. Bảng: `inventory`
Mức tồn kho cho thuốc.

| Cột | Kiểu | Mặc định | Nullable | Ghi chú |
| :--- | :--- | :--- | :--- | :--- |
| **id** | `uuid` | `gen_random_uuid()` | Không | **PK** |
| `medicine_id` | `uuid` | - | Có | FK -> `medicines.id` |
| `batch_number` | `text` | - | Có | Số lô |
| `quantity` | `integer` | `0` | Có | Số lượng tồn |
| `expiry_date` | `date` | - | Có | Hạn sử dụng |
| `created_at` | `timestamp` | `now()` | Có | |
| `updated_at` | `timestamp` | `now()` | Có | |

---

## 8. Bảng: `patient_profiles`
Hồ sơ chi tiết cho bệnh nhân (hỗ trợ nhiều hồ sơ).

| Cột | Kiểu | Mặc định | Nullable | Ghi chú |
| :--- | :--- | :--- | :--- | :--- |
| **id** | `uuid` | `gen_random_uuid()` | Không | **PK** |
| `user_id` | `uuid` | - | Không | FK -> `users.id` |
| `full_name` | `text` | - | Không | Họ tên đầy đủ |
| `dob` | `date` | - | Có | Ngày sinh |
| `gender` | `text` | - | Có | Giới tính |
| `phone` | `text` | - | Có | SĐT |
| `national_id` | `text` | - | Có | CCCD/CMND |
| `health_insurance_code` | `text` | - | Có | Mã BHYT |
| `address_province` | `text` | - | Có | Tỉnh/Thành phố |
| `address_district` | `text` | - | Có | Quận/Huyện |
| `address_ward` | `text` | - | Có | Phường/Xã |
| `address_street` | `text` | - | Có | Đường/Số nhà |
| `email` | `text` | - | Có | |
| `ethnicity` | `text` | - | Có | Dân tộc |

---

## 9. Bảng: `doctor_info`
Hồ sơ mở rộng cho người dùng là bác sĩ.

| Cột | Kiểu | Mặc định | Nullable | Ghi chú |
| :--- | :--- | :--- | :--- | :--- |
| **id** | `uuid` | `gen_random_uuid()` | Không | **PK** |
| `user_id` | `uuid` | - | Không | FK -> `users.id` (Duy nhất) |
| `specialty` | `text` | - | Có | Chuyên khoa |
| `license_number` | `text` | - | Có | Số chứng chỉ hành nghề |
| `experience_years` | `integer` | - | Có | Kinh nghiệm (năm) |
| `bio` | `text` | - | Có | Tiểu sử |
| `rating` | `numeric` | `5.0` | Có | Đánh giá sao |
| `reviews_count` | `integer` | `0` | Có | Số lượt đánh giá |

---

## 10. Bảng: `medical_services`
Danh sách các dịch vụ có sẵn để đặt lịch.

| Cột | Kiểu | Mặc định | Nullable | Ghi chú |
| :--- | :--- | :--- | :--- | :--- |
| **id** | `uuid` | `gen_random_uuid()` | Không | **PK** |
| `name` | `text` | - | Không | Tên dịch vụ |
| `price` | `numeric` | `0` | Có | Giá |
| `category` | `text` | - | Có | Danh mục |

---

## 11. Các Bảng Hệ Thống (`notifications`, `messages`, `user_fcm_tokens`)
*   **`notifications`**: Lưu trữ thông báo trong ứng dụng (`title` - tiêu đề, `body` - nội dung, `type` - loại, `is_read` - đã đọc).
*   **`messages`**: Tin nhắn trò chuyện giữa người dùng (`sender_id` - người gửi, `receiver_id` - người nhận, `content` - nội dung).
*   **`user_fcm_tokens`**: Lưu trữ token Firebase Cloud Messaging cho thông báo đẩy (push notifications).
