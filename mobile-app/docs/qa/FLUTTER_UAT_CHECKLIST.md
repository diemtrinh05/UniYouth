# FLUTTER UAT CHECKLIST

## 1. Mục tiêu
- Xác nhận các luồng nghiệp vụ chính hoạt động đúng từ đăng nhập đến điểm/notification.
- Dùng checklist này như điều kiện chặn release (QA gate).

## 2. Phạm vi API
- `POST /api/Auth/login`
- `POST /api/Auth/forgot-password`
- `POST /api/Auth/verify-reset-otp`
- `POST /api/Auth/reset-password`
- `GET /api/Events`
- `GET /api/Events/{id}`
- `POST /api/events/{eventId}/register`
- `DELETE /api/events/{eventId}/register`
- `POST /api/attendance/checkin`
- `GET /api/users/me/points`
- `GET /api/notifications`
- `PUT /api/notifications/{id}/read`

## 3. Tiền điều kiện
- Build app ở môi trường UAT trỏ đúng backend UAT.
- Có ít nhất 1 tài khoản hợp lệ (`DoanVien` hoặc `HoiVien`).
- Có ít nhất 1 tài khoản test có email hợp lệ để nhận OTP reset password.
- Có dữ liệu sự kiện để test:
  - 1 event còn mở đăng ký.
  - 1 event đã hết hạn đăng ký.
  - 1 event có QR hợp lệ để điểm danh.
  - 1 QR hết hạn hoặc chưa tới giờ hiệu lực.
- Thiết bị có camera + định vị hoạt động bình thường.
- Tester có quyền xem hộp thư email test để lấy OTP.

## 4. Checklist UAT theo luồng chính

## 4.1 Luồng đăng nhập
| ID | Test case | Bước test | Kết quả mong đợi | Pass/Fail |
|---|---|---|---|---|
| UAT-LOGIN-01 | Đăng nhập thành công | Nhập tài khoản hợp lệ, bấm đăng nhập | API `POST /api/Auth/login` trả thành công, vào Home, session được lưu | Pass nếu điều hướng đúng và không lỗi đỏ |
| UAT-LOGIN-02 | Sai mật khẩu | Nhập mật khẩu sai | Hiển thị thông báo lỗi đúng UX, không vào Home | Pass nếu không crash, không treo màn hình |
| UAT-LOGIN-03 | Rate limit login | Bấm đăng nhập liên tục vượt ngưỡng | Nhận `429`, UI hiển thị cooldown và khóa thao tác tạm thời | Pass nếu không gửi spam request |
| UAT-LOGIN-04 | Token hết hạn giữa phiên | Dùng token hết hạn rồi gọi API bảo vệ | Nhận `401`, app quay về login đúng flow | Pass nếu session local bị xóa và điều hướng nhất quán |

## 4.2 Luồng danh sách và chi tiết sự kiện
| ID | Test case | Bước test | Kết quả mong đợi | Pass/Fail |
|---|---|---|---|---|
| UAT-EVENT-01 | Tải danh sách sự kiện | Mở màn hình danh sách sự kiện | API `GET /api/Events` trả dữ liệu, hiển thị list + phân trang | Pass nếu list hiển thị và load thêm được |
| UAT-EVENT-02 | Filter và refresh | Áp dụng filter, kéo refresh | Kết quả lọc đúng, refresh không gây stale-state | Pass nếu dữ liệu đổi đúng theo filter |
| UAT-EVENT-03 | Mở chi tiết sự kiện | Chọn 1 item | API `GET /api/Events/{id}` trả đúng, hiển thị đầy đủ thông tin | Pass nếu không có lỗi `eventId` không hợp lệ |

## 4.3 Luồng đăng ký và hủy đăng ký sự kiện
| ID | Test case | Bước test | Kết quả mong đợi | Pass/Fail |
|---|---|---|---|---|
| UAT-REG-01 | Đăng ký thành công | Ở event hợp lệ, bấm đăng ký | API `POST /api/events/{eventId}/register` thành công, trạng thái UI cập nhật ngay | Pass nếu quay lại list/detail đều đồng bộ trạng thái |
| UAT-REG-02 | Đăng ký event đã hết hạn | Bấm đăng ký event hết hạn | Backend trả lỗi nghiệp vụ (`400`), UI hiện message chuẩn | Pass nếu không crash và không đổi sai trạng thái |
| UAT-REG-03 | Double tap đăng ký | Bấm đăng ký liên tục | Không tạo bản ghi trùng; nhận lỗi hợp lệ (`409` hoặc message đã đăng ký) | Pass nếu không bị đăng ký lặp |
| UAT-REG-04 | Hủy đăng ký thành công | Ở event đã đăng ký, bấm hủy | API `DELETE /api/events/{eventId}/register` thành công, trạng thái UI cập nhật | Pass nếu list/detail đồng bộ sau khi back |

## 4.4 Luồng điểm danh QR (attendance edge cases)
| ID | Test case | Bước test | Kết quả mong đợi | Pass/Fail |
|---|---|---|---|---|
| UAT-ATT-01 | Check-in hợp lệ | Quét QR hợp lệ + bật GPS gần địa điểm | API `POST /api/attendance/checkin` thành công, hiển thị kết quả thành công | Pass nếu có kết quả và trạng thái đã điểm danh |
| UAT-ATT-02 | QR hết hạn/chưa hiệu lực | Quét QR không hợp lệ thời gian | API trả lỗi (`400` hoặc `404` theo rule), UI hiện message đúng | Pass nếu không tạo kết quả thành công giả |
| UAT-ATT-03 | Quá xa vị trí | Quét QR hợp lệ nhưng đứng ngoài phạm vi | API có thể trả `200` với `isValid=false`, UI hiển thị rõ check-in không hợp lệ | Pass nếu trạng thái hiển thị đúng theo response |
| UAT-ATT-04 | Đã check-in trước đó | Check-in lần 2 cùng event | Backend từ chối (`400` hoặc `409` tùy nhánh), UI không báo thành công | Pass nếu không tạo duplicate attendance |
| UAT-ATT-05 | Rate limit check-in | Spam check-in vượt ngưỡng | Nhận `429`, UI cooldown/chặn thao tác tạm thời | Pass nếu app không retry spam |

## 4.5 Luồng điểm cá nhân
| ID | Test case | Bước test | Kết quả mong đợi | Pass/Fail |
|---|---|---|---|---|
| UAT-POINT-01 | Xem tổng quan điểm | Mở màn hình tổng quan điểm | API `GET /api/users/me/points` trả đúng, hiển thị tổng điểm và chỉ số | Pass nếu dữ liệu không rỗng sai |
| UAT-POINT-02 | Đồng bộ điểm sau check-in hợp lệ | Sau check-in hợp lệ, refresh màn điểm | Điểm/tổng quan cập nhật đúng theo backend | Pass nếu không stale dữ liệu |

## 4.6 Luồng notification
| ID | Test case | Bước test | Kết quả mong đợi | Pass/Fail |
|---|---|---|---|---|
| UAT-NOTI-01 | Tải danh sách thông báo | Mở notification center | API `GET /api/notifications` trả danh sách + badge unread đúng | Pass nếu có loading/error/empty rõ ràng |
| UAT-NOTI-02 | Đánh dấu đã đọc 1 thông báo | Bấm mark read 1 item | API `PUT /api/notifications/{id}/read` thành công, badge cập nhật | Pass nếu unread giảm đúng |
| UAT-NOTI-03 | Điều hướng từ thông báo | Bấm vào thông báo có liên kết event | Điều hướng đúng màn liên quan (event detail) | Pass nếu route đúng và không lỗi điều hướng |

## 4.7 Luồng quên mật khẩu OTP
| ID | Test case | Bước test | Kết quả mong đợi | Pass/Fail |
|---|---|---|---|---|
| UAT-OTP-01 | Forgot password với email hợp lệ | Từ login vào `Quên mật khẩu`, nhập email hợp lệ, bấm gửi | API `POST /api/Auth/forgot-password` trả `200`, app chuyển sang màn OTP, hiển thị message trung tính | Pass nếu không leak user existence và điều hướng đúng |
| UAT-OTP-02 | Forgot password với email không tồn tại | Nhập email không tồn tại trong hệ thống | Backend vẫn trả response trung tính, app vẫn vào màn OTP | Pass nếu UI không tiết lộ email có tồn tại hay không |
| UAT-OTP-03 | Validation email sai format | Nhập email sai định dạng rồi submit | Hiển thị lỗi field email, không gọi flow tiếp theo | Pass nếu không sang màn OTP |
| UAT-OTP-04 | Rate limit forgot password | Spam submit forgot password vượt ngưỡng | Nhận `429`, hiển thị message backend/rate limit, không cho spam tiếp | Pass nếu không gửi request lặp không kiểm soát |
| UAT-OTP-05 | Verify OTP thành công | Nhập OTP đúng 6 số nhận từ email | API `POST /api/Auth/verify-reset-otp` trả `200`, app vào màn reset password, lưu `verificationTicket` trong memory | Pass nếu không hiển thị ticket ra UI/log |
| UAT-OTP-06 | Verify OTP sai | Nhập OTP sai | Nhận `400`, hiển thị đúng message backend như `OTP không chính xác.` | Pass nếu message không bị generic hóa |
| UAT-OTP-07 | OTP hết hạn | Chờ quá hạn hoặc dùng OTP cũ đã hết hạn | Nhận `400`, báo OTP hết hạn/không hợp lệ, cho phép resend | Pass nếu email vẫn được giữ để gửi lại mã |
| UAT-OTP-08 | OTP vượt quá số lần thử | Nhập sai OTP nhiều lần tới ngưỡng backend | Nhận `400`, yêu cầu gửi OTP mới, không tiếp tục verify OTP cũ | Pass nếu UI không báo thành công giả |
| UAT-OTP-09 | Resend OTP thành công | Từ màn OTP bấm `Gửi lại mã` sau cooldown | Gọi lại `POST /api/Auth/forgot-password`, reset countdown, clear OTP cũ, chỉ OTP mới nhất còn hiệu lực | Pass nếu flow state giữ email và không giữ ticket cũ |
| UAT-OTP-10 | Reset password thành công | Sau khi verify OTP, nhập mật khẩu mới + xác nhận đúng | API `POST /api/Auth/reset-password` thành công, clear flow state, redirect về login | Pass nếu quay về login và không còn truy cập được reset screen cũ |
| UAT-OTP-11 | Reset password với ticket hết hạn/không hợp lệ | Dùng ticket đã hết hạn hoặc đã dùng | Nhận `400`, clear ticket, quay về bước OTP hoặc forgot password | Pass nếu app không lặp vô hạn và không giữ ticket lỗi |
| UAT-OTP-12 | Validation mật khẩu mới | Nhập mật khẩu ngắn hoặc xác nhận không khớp | Hiển thị lỗi field password/confirm password, không submit thành công | Pass nếu không gọi reset thành công sai |
| UAT-OTP-13 | Route guard reset password | Mở thẳng route reset khi chưa có `verificationTicket` | App chặn truy cập và điều hướng an toàn về đầu flow | Pass nếu không render form reset usable |
| UAT-OTP-14 | Route guard enter OTP | Mở thẳng route OTP khi chưa có email trong flow state | App điều hướng về forgot password | Pass nếu không để verify OTP thiếu ngữ cảnh email |
| UAT-OTP-15 | Reload app giữa flow OTP | Đang ở màn OTP hoặc reset rồi kill/reopen app | Không crash, không tự gọi reset, fallback an toàn về forgot password khi mất state memory | Pass nếu không leak OTP/ticket |
| UAT-OTP-16 | Security logging | Chạy debug build, thực hiện verify/reset flow và quan sát log | Không thấy `otpCode` hoặc `verificationTicket` trong log/request dump | Pass nếu secret luôn bị redact |

## 5. Tiêu chí pass/fail trước release
- PASS toàn luồng khi:
  - Tất cả case P0/P1 trong bảng trên đạt PASS.
  - Không còn lỗi crash/đứng màn hình ở login, event register, check-in, points, notifications.
  - Tất cả case `UAT-OTP-01` đến `UAT-OTP-16` đạt PASS cho build có OTP reset flow.
  - Không có case hiển thị sai trạng thái so với response backend.
- FAIL release khi:
  - Bất kỳ case edge attendance (`UAT-ATT-02/03/04`) fail.
  - Bất kỳ case auth/session (`UAT-LOGIN-01/04`) fail.
  - Bất kỳ case password reset OTP P0 fail (`UAT-OTP-01`, `UAT-OTP-05`, `UAT-OTP-10`, `UAT-OTP-13`, `UAT-OTP-16`).
  - Có lỗi đỏ runtime hoặc app treo trong luồng chính.

## 6. Mẫu ghi nhận kết quả chạy UAT
| Ngày test | Người test | Build | Tổng case | Pass | Fail | Kết luận |
|---|---|---|---:|---:|---:|---|
| yyyy-mm-dd |  |  |  |  |  | GO/NO-GO |

