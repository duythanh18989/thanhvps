# 🚀 ThanhTV VPS Installer v2.0

Script tự động cài đặt và quản lý môi trường Web Server cho VPS Ubuntu.

![License](https://img.shields.io/badge/license-MIT-blue)
![Ubuntu](https://img.shields.io/badge/Ubuntu-20.04%2B-orange)
![Version](https://img.shields.io/badge/version-2.0-success)

---

## ✨ Tính năng

### 🎯 Core Components
- ✅ **Nginx** - Web server hiệu suất cao
- ✅ **PHP** - Đa phiên bản (7.4, 8.1, 8.2, 8.3) với PHP-FPM
- ✅ **MariaDB** - Database server
- ✅ **Redis** - Cache server & session storage
- ✅ **NodeJS** - Runtime cho JavaScript (via NVM)
- ✅ **FileBrowser** - Web-based file manager

### 🛠️ Management Features
- 📁 Quản lý website (thêm/xóa/list)
- 🗄️ Quản lý database (tạo/xóa/export)
- 💾 Backup tự động (website + database)
- ⚙️ Tools quản trị hệ thống
- 🔄 Auto-update script

### 🎨 User Interface
- Giao diện TUI đẹp với **Gum** (fallback: whiptail)
- Menu trực quan, dễ sử dụng
- Logging chi tiết với màu sắc

---

## 📋 Yêu cầu

- Ubuntu 20.04, 22.04 hoặc 24.04 LTS
- Quyền root access
- Kết nối internet

---

## 🚀 Cài đặt

### Quick Start

```bash
# Clone repository
git clone https://github.com/duythanh18989/thanhvps.git
cd thanhvps

# Chạy script cài đặt
sudo bash install.sh
```

### Manual Installation

```bash
# Tải về
wget https://github.com/duythanh18989/thanhvps/archive/refs/heads/main.zip
unzip main.zip
cd thanhvps-main

# Phân quyền
chmod +x install.sh
chmod +x functions/*.sh

# Chạy
sudo bash install.sh
```

---

## ⚙️ Cấu hình

Chỉnh sửa file `config.yml` trước khi cài:

```yaml
# Domain mặc định
default_domain: yourdomain.com

# PHP versions
php_versions: 7.4 8.1 8.2 8.3
default_php: 8.2

# Redis
redis:
  enabled: true
  port: 6379

# NodeJS
nodejs:
  enabled: false  # Set true nếu cần
  default_version: 20

# File Manager
filemanager:
  enabled: true
  port: 8080

# SSL
ssl:
  auto_ssl: true  # Tự động cài Let's Encrypt
```

---

## 📖 Sử dụng

### Command Line Interface

Sau khi cài đặt, bạn có thể sử dụng command `thanhvps` từ bất kỳ đâu:

```bash
# Mở menu chính
thanhvps

# Hoặc các lệnh cụ thể
thanhvps website add        # Thêm website
thanhvps db create          # Tạo database
thanhvps info               # Xem trạng thái
thanhvps restart            # Restart services
thanhvps help               # Xem hướng dẫn
```

### Menu Chính

Sau khi cài xong, script sẽ tự động mở menu quản lý. Hoặc chạy thủ công:

```bash
thanhvps
# hoặc
sudo bash functions/menu.sh
```

### Quản lý Website

**Thêm website mới:**
```
Menu → Quản lý Website → Thêm website mới
```

Script sẽ tự động:
- Tạo thư mục `/var/www/domain.com/public_html`
- Cấu hình Nginx virtual host
- Tạo file PHP test
- Hỗ trợ cài SSL Let's Encrypt

**Xóa website:**
```
Menu → Quản lý Website → Xóa website
```

### Quản lý Database

**Tạo database:**
```
Menu → Quản lý Database → Tạo database mới
```

Script sẽ:
- Tạo database với charset UTF8MB4
- Tạo user riêng cho database
- Random password an toàn

**Export database:**
```
Menu → Quản lý Database → Export database
```

Backup sẽ được lưu tại `/opt/backups/mysql/`

### Backup

**Backup thủ công:**
```
Menu → Backup & Phục hồi → Backup toàn bộ VPS
```

**Cài backup tự động:**
```
Menu → Backup & Phục hồi → Cài cron auto backup
```

Backup sẽ chạy hàng ngày lúc 2:30 AM

### Quản trị Hệ thống

```
Menu → Quản trị Hệ thống
```

Các tính năng:
- Xem thông tin hệ thống (CPU, RAM, Disk)
- Restart các dịch vụ
- Dọn dẹp hệ thống
- Cập nhật system packages
- Kiểm tra dung lượng

---

## 📂 Cấu trúc thư mục

```
thanhvps/
├── install.sh              # Script cài đặt chính
├── config.yml              # File cấu hình
├── README.md               # Tài liệu này
├── version.txt             # Phiên bản
├── functions/              # Các module chức năng
│   ├── utils.sh           # Utilities & logging
│   ├── menu.sh            # Menu management
│   ├── setup_nginx.sh     # Nginx & website
│   ├── setup_php.sh       # PHP installation
│   ├── setup_mysql.sh     # MariaDB & DB management
│   ├── setup_redis.sh     # Redis cache
│   ├── setup_nodejs.sh    # NodeJS via NVM
│   ├── setup_filemanager.sh  # FileBrowser
│   ├── setup_ssl.sh       # Let's Encrypt SSL
│   ├── backup.sh          # Backup tools
│   ├── system.sh          # System admin tools
│   └── autoupdate.sh      # Auto-update script
└── logs/                   # Log files
    └── install.log        # Installation log
```

---

## 🔧 Advanced Usage

### Thêm website với CLI (không dùng menu)

```bash
# Source functions
source functions/utils.sh
source functions/setup_nginx.sh

# Add website
add_website
```

### Tạo database với CLI

```bash
source functions/utils.sh
source functions/setup_mysql.sh

create_db
```

### Check PHP versions

```bash
# List installed PHP
ls /etc/php/

# Check PHP-FPM status
systemctl status php8.2-fpm
```

### Redis commands

```bash
# Check Redis
redis-cli ping

# Get info
redis-cli INFO

# Flush cache
redis-cli FLUSHALL
```

---

## 🐛 Troubleshooting

### PHP-FPM không start

```bash
# Check logs
tail -f /var/log/php8.2-fpm.log

# Restart
systemctl restart php8.2-fpm
```

### Nginx không reload

```bash
# Test config
nginx -t

# Check logs
tail -f /var/log/nginx/error.log
```

### MySQL không kết nối được

```bash
# Check service
systemctl status mariadb

# Check logs
tail -f /var/log/mysql/error.log

# Reset root password
sudo mysql
ALTER USER 'root'@'localhost' IDENTIFIED BY 'new_password';
FLUSH PRIVILEGES;
```

---

## 📝 Log Files

- **Installation log**: `logs/install.log`
- **Nginx access**: `/var/log/nginx/<domain>.access.log`
- **Nginx error**: `/var/log/nginx/<domain>.error.log`
- **PHP-FPM**: `/var/log/php<version>-fpm.log`
- **MariaDB**: `/var/log/mysql/error.log`
- **Redis**: `/var/log/redis/redis-server.log`

---

## 🔐 Security

Script tự động:
- ✅ Random passwords cho MySQL & FileBrowser
- ✅ Secure MySQL installation (xóa anonymous users, test database)
- ✅ Server tokens off (ẩn version)
- ✅ Security headers (X-Frame-Options, X-XSS-Protection)
- ⚠️ **Khuyến nghị**: Cài Fail2ban và UFW firewall

---

## 🆕 Update

```bash
cd thanhvps
git pull origin main
# hoặc
Menu → Auto Update Script
```

---

## 🤝 Contributing

Mọi đóng góp đều được hoan nghênh! Vui lòng:
1. Fork repo
2. Tạo branch mới (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Tạo Pull Request

---

## 📄 License

MIT License - xem file LICENSE để biết thêm chi tiết

---

## 👨‍💻 Author

**ThanhTV**
- GitHub: [@duythanh18989](https://github.com/duythanh18989)

---

## 🙏 Acknowledgments

- [Nginx](https://nginx.org/)
- [PHP](https://www.php.net/)
- [MariaDB](https://mariadb.org/)
- [Redis](https://redis.io/)
- [Gum](https://github.com/charmbracelet/gum)
- [FileBrowser](https://filebrowser.org/)

---

⭐ Nếu project hữu ích, hãy cho một star nhé!
