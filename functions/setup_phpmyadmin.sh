#!/bin/bash
# ========================================================
# 🗄️ setup_phpmyadmin.sh - Install phpMyAdmin
# ========================================================

install_phpmyadmin() {
  log_info "🗄️ Đang cài phpMyAdmin..."
  
  # Install dependencies
  apt-get install -y wget unzip php-mbstring php-zip php-gd php-json php-curl &>/dev/null
  
  # Get latest version
  PHPMYADMIN_VERSION="5.2.1"
  PMA_DIR="/var/www/phpmyadmin"
  
  # Download phpMyAdmin
  cd /tmp
  wget -q "https://files.phpmyadmin.net/phpMyAdmin/${PHPMYADMIN_VERSION}/phpMyAdmin-${PHPMYADMIN_VERSION}-all-languages.zip" -O phpmyadmin.zip
  
  if [ ! -f "phpmyadmin.zip" ]; then
    log_error "❌ Failed to download phpMyAdmin"
    return 1
  fi
  
  # Extract
  unzip -q phpmyadmin.zip
  rm -rf "$PMA_DIR"
  mv "phpMyAdmin-${PHPMYADMIN_VERSION}-all-languages" "$PMA_DIR"
  rm -f phpmyadmin.zip
  
  # Set permissions
  chown -R www-data:www-data "$PMA_DIR"
  chmod -R 755 "$PMA_DIR"
  
  # Create config
  cat > "$PMA_DIR/config.inc.php" <<'EOF'
<?php
declare(strict_types=1);

$cfg['blowfish_secret'] = '$(openssl rand -base64 32)';

$i = 0;
$i++;
$cfg['Servers'][$i]['auth_type'] = 'cookie';
$cfg['Servers'][$i]['host'] = 'localhost';
$cfg['Servers'][$i]['compress'] = false;
$cfg['Servers'][$i]['AllowNoPassword'] = false;

$cfg['UploadDir'] = '';
$cfg['SaveDir'] = '';
$cfg['TempDir'] = '/tmp';

// Security
$cfg['LoginCookieValidity'] = 3600;
$cfg['LoginCookieStore'] = 0;
EOF
  
  # Create Nginx vhost for phpMyAdmin
  local PMA_DOMAIN=${CONFIG_phpmyadmin_domain:-pma.$(hostname -f)}
  local PMA_PORT=${CONFIG_phpmyadmin_port:-8081}
  
  # Option 1: Subdomain
  if [ "$CONFIG_phpmyadmin_mode" = "subdomain" ] && [ -n "$CONFIG_phpmyadmin_domain" ]; then
    cat > /etc/nginx/sites-available/phpmyadmin.conf <<EOF
server {
    listen 80;
    server_name $PMA_DOMAIN;
    root $PMA_DIR;
    index index.php;
    
    access_log /var/log/nginx/phpmyadmin-access.log;
    error_log /var/log/nginx/phpmyadmin-error.log;
    
    location / {
        try_files \$uri \$uri/ =404;
    }
    
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.2-fpm.sock;
    }
    
    location ~ /\.ht {
        deny all;
    }
}
EOF
    ln -sf /etc/nginx/sites-available/phpmyadmin.conf /etc/nginx/sites-enabled/
    log_info "✅ phpMyAdmin: http://$PMA_DOMAIN"
    
  # Option 2: Port-based
  else
    cat > /etc/nginx/sites-available/phpmyadmin.conf <<EOF
server {
    listen $PMA_PORT;
    server_name _;
    root $PMA_DIR;
    index index.php;
    
    access_log /var/log/nginx/phpmyadmin-access.log;
    error_log /var/log/nginx/phpmyadmin-error.log;
    
    location / {
        try_files \$uri \$uri/ =404;
    }
    
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.2-fpm.sock;
    }
    
    location ~ /\.ht {
        deny all;
    }
}
EOF
    ln -sf /etc/nginx/sites-available/phpmyadmin.conf /etc/nginx/sites-enabled/
    local SERVER_IP=$(hostname -I | awk '{print $1}')
    log_info "✅ phpMyAdmin: http://$SERVER_IP:$PMA_PORT"
  fi
  
  # Reload Nginx
  nginx -t && systemctl reload nginx
  
  log_info "✅ phpMyAdmin installed successfully!"
  log_info "📝 Login with MySQL root credentials"
}

# Uninstall phpMyAdmin
uninstall_phpmyadmin() {
  log_info "Removing phpMyAdmin..."
  
  rm -rf /var/www/phpmyadmin
  rm -f /etc/nginx/sites-enabled/phpmyadmin.conf
  rm -f /etc/nginx/sites-available/phpmyadmin.conf
  
  systemctl reload nginx
  
  log_info "✅ phpMyAdmin removed"
}

# Show phpMyAdmin info
show_phpmyadmin_info() {
  if [ ! -d "/var/www/phpmyadmin" ]; then
    log_error "❌ phpMyAdmin chưa được cài đặt"
    return 1
  fi
  
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🗄️  THÔNG TIN PHPMYADMIN"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  
  # Check config
  if [ -f "/etc/nginx/sites-available/phpmyadmin.conf" ]; then
    local url=""
    if grep -q "listen 80" /etc/nginx/sites-available/phpmyadmin.conf; then
      # Subdomain mode
      local domain=$(grep "server_name" /etc/nginx/sites-available/phpmyadmin.conf | awk '{print $2}' | tr -d ';')
      url="http://$domain"
    else
      # Port mode
      local port=$(grep "listen" /etc/nginx/sites-available/phpmyadmin.conf | head -1 | awk '{print $2}' | tr -d ';')
      local ip=$(hostname -I | awk '{print $1}')
      url="http://$ip:$port"
    fi
    
    echo "🌐 URL: $url"
  fi
  
  echo ""
  echo "📝 Thông tin đăng nhập:"
  echo "   User: root"
  echo "   Pass: <MySQL root password>"
  echo ""
  echo "💡 Lấy mật khẩu MySQL root từ: $INSTALL_LOG"
  echo ""
  
  # Show MySQL root password if available
  if [ -f "$INSTALL_LOG" ]; then
    local mysql_pass=$(grep "MySQL root password:" "$INSTALL_LOG" | tail -1 | cut -d':' -f2- | xargs)
    if [ -n "$mysql_pass" ]; then
      echo "🔑 MySQL root password: $mysql_pass"
    fi
  fi
}

# List MySQL users
list_mysql_users() {
  if ! systemctl is-active --quiet mariadb; then
    log_error "❌ MariaDB service không chạy"
    return 1
  fi
  
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "👥 DANH SÁCH USER MYSQL"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  
  # Get MySQL root password
  local mysql_pass=""
  if [ -f "$INSTALL_LOG" ]; then
    mysql_pass=$(grep "MySQL root password:" "$INSTALL_LOG" | tail -1 | cut -d':' -f2- | xargs)
  fi
  
  if [ -z "$mysql_pass" ]; then
    if $use_gum; then
      mysql_pass=$(gum input --password --placeholder "Nhập MySQL root password")
    else
      read -sp "Nhập MySQL root password: " mysql_pass
      echo ""
    fi
  fi
  
  mysql -uroot -p"$mysql_pass" -e "SELECT User, Host FROM mysql.user ORDER BY User;" 2>/dev/null || {
    log_error "❌ Không thể kết nối MySQL. Kiểm tra mật khẩu root."
    return 1
  }
}

# Change MySQL user password
change_mysql_password() {
  if ! systemctl is-active --quiet mariadb; then
    log_error "❌ MariaDB service không chạy"
    return 1
  fi
  
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🔐 ĐỔI MẬT KHẨU MYSQL USER"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  
  # Get MySQL root password
  local current_root_pass=""
  if [ -f "$INSTALL_LOG" ]; then
    current_root_pass=$(grep "MySQL root password:" "$INSTALL_LOG" | tail -1 | cut -d':' -f2- | xargs)
  fi
  
  if [ -z "$current_root_pass" ]; then
    if $use_gum; then
      current_root_pass=$(gum input --password --placeholder "Nhập MySQL root password hiện tại")
    else
      read -sp "Nhập MySQL root password hiện tại: " current_root_pass
      echo ""
    fi
  fi
  
  # List users first
  echo ""
  echo "Danh sách users:"
  mysql -uroot -p"$current_root_pass" -e "SELECT User, Host FROM mysql.user WHERE User != '' ORDER BY User;" 2>/dev/null || {
    log_error "❌ Không thể kết nối MySQL. Kiểm tra mật khẩu root."
    return 1
  }
  echo ""
  
  if $use_gum; then
    username=$(gum input --placeholder "Nhập username (mặc định: root)")
    username=${username:-root}
    
    new_password=$(gum input --password --placeholder "Nhập mật khẩu mới (tối thiểu 8 ký tự)")
  else
    read -p "Nhập username [root]: " username
    username=${username:-root}
    
    read -sp "Nhập mật khẩu mới: " new_password
    echo ""
  fi
  
  # Validate password length
  if [ ${#new_password} -lt 8 ]; then
    log_error "❌ Mật khẩu phải có ít nhất 8 ký tự"
    return 1
  fi
  
  # Change password
  mysql -uroot -p"$current_root_pass" -e "ALTER USER '${username}'@'localhost' IDENTIFIED BY '${new_password}';" 2>/dev/null || {
    log_error "❌ Không thể đổi mật khẩu. Kiểm tra user có tồn tại không."
    return 1
  }
  
  mysql -uroot -p"$current_root_pass" -e "FLUSH PRIVILEGES;" 2>/dev/null
  
  log_info "✅ Đã đổi mật khẩu cho user: $username"
  
  # Update log file if root password changed
  if [ "$username" = "root" ] && [ -f "$INSTALL_LOG" ]; then
    echo "MySQL root password: $new_password (changed on $(date '+%Y-%m-%d %H:%M:%S'))" >> "$INSTALL_LOG"
    log_info "📝 Mật khẩu đã được lưu vào: $INSTALL_LOG"
  fi
}

# Reset MySQL root password (recovery mode)
reset_mysql_root_password() {
  if ! systemctl is-active --quiet mariadb; then
    log_error "❌ MariaDB service không chạy"
    return 1
  fi
  
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🔄 RESET MẬT KHẨU MYSQL ROOT"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "⚠️  Tính năng này sẽ:"
  echo "   1. Dừng MySQL service"
  echo "   2. Khởi động MySQL ở chế độ skip-grant-tables"
  echo "   3. Reset mật khẩu root"
  echo "   4. Khởi động lại MySQL bình thường"
  echo ""
  
  if $use_gum; then
    confirm=$(gum choose "Tiếp tục reset" "Hủy bỏ")
    if [[ "$confirm" == "Hủy bỏ" ]]; then
      log_info "❌ Đã hủy reset password"
      return 0
    fi
    
    new_password=$(gum input --password --placeholder "Nhập mật khẩu ROOT mới (tối thiểu 8 ký tự)")
  else
    read -p "Bạn có chắc muốn reset password? (y/n): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
      log_info "❌ Đã hủy reset password"
      return 0
    fi
    
    read -sp "Nhập mật khẩu ROOT mới: " new_password
    echo ""
  fi
  
  # Validate password length
  if [ ${#new_password} -lt 8 ]; then
    log_error "❌ Mật khẩu phải có ít nhất 8 ký tự"
    return 1
  fi
  
  log_info "🔄 Đang dừng MySQL service..."
  systemctl stop mariadb
  
  log_info "🔄 Khởi động MySQL ở safe mode..."
  
  # Start MySQL in safe mode
  mysqld_safe --skip-grant-tables --skip-networking &
  SAFE_PID=$!
  
  # Wait for MySQL to start
  sleep 5
  
  log_info "🔄 Đang reset mật khẩu root..."
  
  # Reset password
  mysql -e "FLUSH PRIVILEGES;" 2>/dev/null
  mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${new_password}';" 2>/dev/null || {
    # Try old method for older MySQL versions
    mysql -e "UPDATE mysql.user SET Password=PASSWORD('${new_password}') WHERE User='root';" 2>/dev/null
    mysql -e "UPDATE mysql.user SET authentication_string=PASSWORD('${new_password}') WHERE User='root';" 2>/dev/null
  }
  mysql -e "FLUSH PRIVILEGES;" 2>/dev/null
  
  # Kill safe mode MySQL
  log_info "🔄 Dừng safe mode..."
  kill $SAFE_PID 2>/dev/null
  sleep 2
  
  # Make sure all mysql processes are stopped
  killall mysqld 2>/dev/null
  sleep 2
  
  # Start MySQL normally
  log_info "🔄 Khởi động MySQL bình thường..."
  systemctl start mariadb
  
  sleep 3
  
  # Test new password
  if mysql -uroot -p"$new_password" -e "SELECT 1;" &>/dev/null; then
    log_info "✅ Reset mật khẩu root thành công!"
    
    # Update log file
    if [ -f "$INSTALL_LOG" ]; then
      echo "MySQL root password: $new_password (reset on $(date '+%Y-%m-%d %H:%M:%S'))" >> "$INSTALL_LOG"
      log_info "📝 Mật khẩu đã được lưu vào: $INSTALL_LOG"
    fi
  else
    log_error "❌ Reset mật khẩu thất bại. Vui lòng kiểm tra lại."
    return 1
  fi
}
