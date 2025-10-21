# 🚀 ThanhTV VPS – Hệ thống quản lý VPS tự động (by [ThanhTV](https://github.com/duythanh18989))

![License](https://img.shields.io/badge/license-MIT-blue)
![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04%2B-orange)
![Shell](https://img.shields.io/badge/Bash-Script-green)
![Version](https://img.shields.io/badge/version-1.5.2-success)

---

## 🎯 Giới thiệu

**ThanhTV VPS** là script quản lý VPS “tất cả trong một” viết bằng Bash,  
giúp bạn **tự động cài đặt – quản trị – backup – cập nhật** VPS Ubuntu chỉ với 1 lệnh duy nhất.

> Mục tiêu: *Đơn giản, mạnh mẽ, thân thiện, và auto-update qua GitHub.*

---

## ⚙️ Tính năng nổi bật

| Nhóm chức năng | Mô tả |
|----------------|-------|
| 🌐 **Website Manager** | Tạo / xóa site, chọn PHP version, auto SSL |
| 🗄️ **Database Manager** | Tạo / xóa DB, random password, MariaDB tối ưu |
| 💾 **Backup System** | Backup toàn VPS hoặc từng domain, cron tự động |
| ⚙️ **System Tools** | Restart dịch vụ, cleanup, update apt, xem cấu hình |
| 🔄 **Auto Update** | Kiểm tra & cập nhật script mới từ GitHub |
| 🧩 **Multi PHP** | Hỗ trợ PHP 7.4 / 8.1 / 8.2 / 8.3 |
| 🔐 **Bảo mật nâng cao** | Đổi SSH port, user `www-data`, SSL Let's Encrypt |
| 🧠 **File Manager** | Tích hợp FileBrowser (UI đẹp) |
| ☁️ **Cloudflare Tunnel (sắp ra mắt)** | Public site ra Internet khi dev/test |

---

## 🚀 Cài đặt nhanh

> VPS yêu cầu: **Ubuntu 22.04 LTS** hoặc mới hơn  
> Quyền: **root hoặc user có sudo**

Chạy 1 lệnh duy nhất:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/duythanh18989/thanhvps/refs/heads/master/install.sh)
