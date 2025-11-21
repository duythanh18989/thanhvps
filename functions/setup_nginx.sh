#!/bin/bash
# ============================================================
# 🌐 MODULE: CÀI ĐẶT & QUẢN LÝ WEBSITE (Nginx + PHP)
# ------------------------------------------------------------
# Tác giả: ThanhTV
# Version: v2.0
# Mục tiêu:
#   - Cài đặt Nginx
#   - Tạo / Xóa website
#   - Tự động lấy PHP version từ config.yml (nếu user không chọn)
#   - Cấu hình Nginx tối ưu (gzip + brotli + cache + headers)
#   - Ghi log vào logs/install.log
# ============================================================

# 🧩 Đường dẫn cơ bản - nếu chưa được set từ install.sh
if [ -z "$BASE_DIR" ]; then
  BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi
LOG_FILE="$BASE_DIR/logs/install.log"

# ------------------------------------------------------------
# 🔧 HÀM: Đọc giá trị từ config.yml
# ------------------------------------------------------------
read_config() {
  local key="$1"
  local default="$2"
  local value
  
  # Try to read from exported CONFIG_ variables first
  local var_name="CONFIG_${key}"
  if [ -n "${!var_name}" ]; then
    echo "${!var_name}"
    return 0
  fi
  
  # Fallback to reading from file
  if [ -f "$BASE_DIR/config.yml" ]; then
    value=$(grep "^${key}:" "$BASE_DIR/config.yml" | head -n1 | cut -d':' -f2- | xargs)
  fi
  
  # Return value or default
  echo "${value:-$default}"
}

# ------------------------------------------------------------
# � HÀM: Install Nginx
# ------------------------------------------------------------
install_nginx() {
  local DOMAIN=${1:-"localhost"}
  
  log_info "Đang cài đặt Nginx..."
  
  # Kiểm tra đã cài chưa
  if command_exists nginx; then
    log_info "Nginx đã được cài đặt"
    if service_is_active nginx; then
      log_info "✅ Nginx đang chạy"
      nginx -v 2>&1 | grep -o 'nginx/[0-9.]*'
      return 0
    fi
  fi
  
  # Chờ apt lock
  wait_for_apt
  
  # Cài đặt Nginx
  log_info "Cài đặt Nginx từ apt..."
  if ! apt-get install -y nginx &>/dev/null; then
    log_error "Không thể cài đặt Nginx!"
    return 1
  fi
  
  # Cấu hình Nginx
  log_info "Cấu hình Nginx..."
  
  # Backup config gốc
  if [ -f /etc/nginx/nginx.conf ]; then
    cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak
  fi
  
  # Tối ưu nginx.conf
  cat > /etc/nginx/nginx.conf <<'NGINX_CONF'
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
    worker_connections 2048;
    multi_accept on;
    use epoll;
}

http {
    # Basic Settings
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    server_tokens off;
    client_max_body_size 128M;

    # MIME Types
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # SSL Settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;

    # Logging
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    # Gzip Compression
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript 
               application/json application/javascript application/xml+rss 
               application/rss+xml font/truetype font/opentype 
               application/vnd.ms-fontobject image/svg+xml;

    # Virtual Host Configs
    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
NGINX_CONF
  
  # Xóa default site
  rm -f /etc/nginx/sites-enabled/default
  
  # Tạo site mặc định
  if [ "$DOMAIN" != "localhost" ]; then
    log_info "Tạo virtual host cho $DOMAIN..."
    
    mkdir -p "/var/www/$DOMAIN/public_html"
    
    cat > "/etc/nginx/sites-available/$DOMAIN.conf" <<EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    
    root /var/www/$DOMAIN/public_html;
    index index.php index.html index.htm;
    
    access_log /var/log/nginx/${DOMAIN}.access.log;
    error_log /var/log/nginx/${DOMAIN}.error.log;
    
    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }
    
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php${CONFIG_default_php:-8.2}-fpm.sock;
    }
    
    location ~ /\.ht {
        deny all;
    }
}
EOF
    
    ln -sf "/etc/nginx/sites-available/$DOMAIN.conf" /etc/nginx/sites-enabled/
    
    # Tạo file test
    cat > "/var/www/$DOMAIN/public_html/index.php" <<'EOF'
<?php
phpinfo();
EOF
    
    chown -R www-data:www-data "/var/www/$DOMAIN"
  fi
  
  # Test config
  if ! nginx -t &>/dev/null; then
    log_error "Nginx config có lỗi!"
    return 1
  fi
  
  # Enable và start
  systemctl enable nginx &>/dev/null
  systemctl restart nginx
  
  if service_is_active nginx; then
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "✅ Nginx đã được cài đặt và đang chạy"
    log_info "🌐 Domain: $DOMAIN"
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  else
    log_error "Nginx không khởi động được"
    return 1
  fi
  
  echo "$(date '+%Y-%m-%d %H:%M:%S') | INSTALL NGINX | $DOMAIN" >> "$LOG_FILE"
  
  return 0
}

# ------------------------------------------------------------
# �🔍 HÀM: Validate domain hợp lệ
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
  default_php=$(read_config "default_php" "8.2")
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

    # ⚡ Gzip compression
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css application/json application/javascript application/xml image/svg+xml;
    gzip_min_length 256;

    # 📁 Root location
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    # 🧠 Static cache
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|woff2|ttf|svg|webp)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
        access_log off;
    }

    # 🧩 PHP handler
    location ~ \.php$ {
        try_files \$uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/run/php/php${phpv}-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_read_timeout 120s;
        fastcgi_buffer_size 128k;
        fastcgi_buffers 256 16k;
        fastcgi_busy_buffers_size 256k;
        fastcgi_temp_file_write_size 256k;
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
