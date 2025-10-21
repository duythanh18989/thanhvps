#!/bin/bash
# ============================================================
# 🌐 MODULE: CÀI ĐẶT & QUẢN LÝ WEBSITE (Nginx + PHP)
# ------------------------------------------------------------
# Tác giả: ThanhTV
# Version: v2.0
# Mục tiêu:
#   - Tạo / Xóa website
#   - Tự động lấy PHP version từ config.yml (nếu user không chọn)
#   - Cấu hình Nginx tối ưu (gzip + brotli + cache + headers)
#   - Ghi log vào logs/install.log
# ============================================================

# 🧩 Đường dẫn cơ bản
BASE_DIR=$(dirname "$(realpath "$0")")
LOG_FILE="$BASE_DIR/logs/install.log"
CONFIG_FILE="$BASE_DIR/config.yml"

# ------------------------------------------------------------
# 🔧 HÀM: Đọc giá trị từ config.yml (dạng key: value)
# ------------------------------------------------------------
read_config() {
  local key="$1"
  awk -F': ' -v k="$key" '$1==k {print $2}' "$CONFIG_FILE" | xargs
}

# ------------------------------------------------------------
# 🔍 HÀM: Validate domain hợp lệ
# ------------------------------------------------------------
validate_domain() {
  local domain=$1
  if [[ $domain =~ ^[a-zA-Z0-9.-]+$ ]]; then
    return 0
  else
    echo "❌ Domain không hợp lệ. Chỉ dùng a-z, 0-9, dấu . và -"
    return 1
  fi
}

# ------------------------------------------------------------
# 🧱 HÀM: Tạo website mới
# ------------------------------------------------------------
add_website() {
  clear
  echo "🌐 Thêm website mới"
  echo "-------------------------------------------"
  read -p "👉 Nhập domain (ví dụ: mysite.com): " domain
  validate_domain "$domain" || return

  # Kiểm tra trùng domain
  if [ -f "/etc/nginx/sites-available/${domain}.conf" ]; then
    echo "⚠️  Domain này đã tồn tại!"
    return
  fi

  # Lấy default PHP version từ config.yml
  default_php=$(read_config "default_php")
  echo "🧩 Chọn phiên bản PHP (Enter để dùng mặc định: $default_php)"
  read phpv
  phpv=${phpv:-$default_php}

  # Tạo thư mục web root
  web_root="/var/www/$domain/public_html"
  mkdir -p "$web_root"
  chown -R www-data:www-data "/var/www/$domain"
  chmod -R 755 "/var/www/$domain"

  # File index test
  cat <<EOF > "$web_root/index.php"
<?php
echo "<h1>Website hoạt động!</h1>";
echo "<p>Domain: $domain</p>";
echo "<p>PHP version: $phpv</p>";
phpinfo();
EOF

  # File Nginx config tối ưu
  conf_path="/etc/nginx/sites-available/${domain}.conf"
  cat <<EOF > "$conf_path"
server {
    listen 80;
    server_name $domain www.$domain;

    root $web_root;
    index index.php index.html;

    access_log /var/log/nginx/${domain}.access.log;
    error_log /var/log/nginx/${domain}.error.log;

    # 🔒 Security headers
    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";
    add_header X-XSS-Protection "1; mode=block";

    # ⚡ Gzip + Brotli
    gzip on;
    gzip_types text/plain text/css application/json application/javascript application/xml image/svg+xml;
    gzip_min_length 256;
    brotli on;
    brotli_comp_level 5;
    brotli_types text/plain text/css application/json application/javascript application/xml image/svg+xml;

    # 🧠 Static cache
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|woff2|ttf|svg)$ {
        expires 30d;
        access_log off;
    }

    # 🧩 PHP handler
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php${phpv}-fpm.sock;
        fastcgi_read_timeout 120s;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

  # Enable site
  ln -sf "$conf_path" /etc/nginx/sites-enabled/

  # Kiểm tra và reload Nginx
  nginx -t && systemctl reload nginx

  # 🔐 Hỏi cài SSL
  read -p "🔒 Cài SSL Let's Encrypt cho $domain? (y/n): " ssl
  if [[ "$ssl" == "y" || "$ssl" == "Y" ]]; then
    if command -v certbot &>/dev/null; then
      certbot --nginx -d "$domain" -d "www.$domain"
    else
      echo "⚠️  certbot chưa cài, bỏ qua SSL."
    fi
  fi

  # 🧾 Ghi log
  echo "$(date '+%Y-%m-%d %H:%M:%S') | ADD SITE | $domain | PHP $phpv" >> "$LOG_FILE"

  echo "✅ Website $domain đã được tạo!"
  echo "📂 Thư mục: $web_root"
  echo "💾 Log: /var/log/nginx/${domain}.access.log"
  echo "🐘 PHP: $phpv"
  echo "-------------------------------------------"
}

# ------------------------------------------------------------
# ❌ HÀM: Xóa website
# ------------------------------------------------------------
remove_website() {
  clear
  echo "❌ Xóa website"
  echo "-------------------------------------------"
  read -p "👉 Nhập domain cần xóa: " domain

  if [ ! -f "/etc/nginx/sites-available/${domain}.conf" ]; then
    echo "⚠️  Domain không tồn tại!"
    return
  fi

  read -p "⚠️  Xác nhận xóa toàn bộ website $domain (y/n)? " confirm
  [[ "$confirm" != "y" && "$confirm" != "Y" ]] && return

  rm -f "/etc/nginx/sites-available/${domain}.conf"
  rm -f "/etc/nginx/sites-enabled/${domain}.conf"
  rm -rf "/var/www/${domain}"

  nginx -t && systemctl reload nginx

  echo "$(date '+%Y-%m-%d %H:%M:%S') | REMOVE SITE | $domain" >> "$LOG_FILE"
  echo "✅ Website $domain đã được xóa."
}

# ------------------------------------------------------------
# 📋 HÀM: Danh sách website hiện có
# ------------------------------------------------------------
list_websites() {
  echo "🌐 Danh sách website:"
  echo "-------------------------------------------"
  ls /etc/nginx/sites-available | sed 's/\.conf//'
  echo "-------------------------------------------"
}

# ------------------------------------------------------------
# 🔍 HÀM: Xem log website (error log)
# ------------------------------------------------------------
view_logs() {
  read -p "👉 Nhập domain cần xem log: " domain
  log_file="/var/log/nginx/${domain}.error.log"
  if [ -f "$log_file" ]; then
    tail -n 30 -f "$log_file"
  else
    echo "⚠️  Không tìm thấy log cho domain này."
  fi
}

# ------------------------------------------------------------
# 🔄 HÀM: Restart Nginx & PHP
# ------------------------------------------------------------
restart_nginx_php() {
  echo "🔄 Restart Nginx & PHP-FPM..."
  systemctl restart nginx
  for v in 7.4 8.1 8.2 8.3; do
    systemctl restart php${v}-fpm 2>/dev/null
  done
  echo "✅ Dịch vụ web đã restart thành công!"
}
