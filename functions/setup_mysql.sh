#!/bin/bash
# ========================================================
# 🗄️ setup_mysql.sh - Cài đặt MariaDB & Database Management
# Version: 2.0
# ========================================================

install_mysql() {
  local MYSQL_PASS=$1
  
  log_info "Đang cài đặt MariaDB Server..."
  
  # Kiểm tra đã cài chưa
  if command_exists mysql; then
    log_info "MariaDB đã được cài đặt"
    if service_is_active mariadb || service_is_active mysql; then
      log_info "✅ MariaDB đang chạy"
      return 0
    fi
  fi
  
  # Chờ apt lock
  wait_for_apt
  
  # Cài đặt MariaDB
  log_info "Cài đặt MariaDB..."
  if ! apt-get install -y mariadb-server mariadb-client &>/dev/null; then
    log_error "Không thể cài đặt MariaDB!"
    return 1
  fi
  
  # Enable và start service
  systemctl enable mariadb &>/dev/null
  systemctl start mariadb
  
  # Đợi service khởi động
  sleep 3
  
  if ! service_is_active mariadb; then
    log_error "MariaDB service không khởi động được"
    return 1
  fi
  
  log_info "Đang thiết lập mật khẩu root..."
  
  # Set root password
  if ! mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED VIA mysql_native_password USING PASSWORD('$MYSQL_PASS'); FLUSH PRIVILEGES;" &>/dev/null; then
    log_warn "Có thể root đã có mật khẩu, thử phương pháp khác..."
    mysql -e "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('$MYSQL_PASS'); FLUSH PRIVILEGES;" &>/dev/null
  fi
  
  # Secure installation (tự động)
  mysql -uroot -p"$MYSQL_PASS" <<EOF &>/dev/null
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF
  
  # Cấu hình MariaDB
  local my_cnf="/etc/mysql/mariadb.conf.d/50-server.cnf"
  if [ -f "$my_cnf" ]; then
    log_info "Tối ưu cấu hình MariaDB..."
    
    # Backup
    cp "$my_cnf" "${my_cnf}.bak"
    
    # Thêm/sửa cấu hình
    if ! grep -q "character-set-server" "$my_cnf"; then
      sed -i '/\[mysqld\]/a character-set-server = utf8mb4' "$my_cnf"
      sed -i '/\[mysqld\]/a collation-server = utf8mb4_unicode_ci' "$my_cnf"
      sed -i '/\[mysqld\]/a max_connections = 200' "$my_cnf"
      sed -i '/\[mysqld\]/a innodb_buffer_pool_size = 256M' "$my_cnf"
    fi
    
    systemctl restart mariadb
  fi
  
  log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  log_info "✅ MariaDB đã được cài đặt và cấu hình"
  log_info "🔐 Root Password: $MYSQL_PASS"
  log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  
  # Ghi log
  echo "$(date '+%Y-%m-%d %H:%M:%S') | INSTALL MARIADB | root_pass: $MYSQL_PASS" >> "$BASE_DIR/logs/install.log"
  
  return 0
}

# === DATABASE MANAGEMENT FUNCTIONS ===

# Create database
create_db() {
  clear
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🗄️  TẠO DATABASE MỚI"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  
  read -p "👉 Nhập tên database: " dbname
  
  if [ -z "$dbname" ]; then
    log_error "Tên database không được để trống!"
    return 1
  fi
  
  read -p "👉 Nhập username (Enter để dùng tên giống db): " dbuser
  dbuser=${dbuser:-$dbname}
  
  # Random password
  local dbpass=$(random_password 16)
  read -p "👉 Nhập password (Enter để random): " user_pass
  dbpass=${user_pass:-$dbpass}
  
  read -p "👉 Nhập MySQL root password: " -s root_pass
  echo ""
  
  # Tạo database
  log_info "Đang tạo database..."
  
  mysql -uroot -p"$root_pass" <<EOF
CREATE DATABASE IF NOT EXISTS \`$dbname\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$dbuser'@'localhost' IDENTIFIED BY '$dbpass';
GRANT ALL PRIVILEGES ON \`$dbname\`.* TO '$dbuser'@'localhost';
FLUSH PRIVILEGES;
EOF
  
  if [ $? -eq 0 ]; then
    log_info "✅ Database đã được tạo thành công!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📋 THÔNG TIN DATABASE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Database: $dbname"
    echo "Username: $dbuser"
    echo "Password: $dbpass"
    echo "Host: localhost"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Ghi vào log
    echo "$(date '+%Y-%m-%d %H:%M:%S') | CREATE DB | $dbname | $dbuser | $dbpass" >> "$BASE_DIR/logs/install.log"
  else
    log_error "Không thể tạo database! Kiểm tra password root."
  fi
}

# Delete database
delete_db() {
  clear
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "❌ XÓA DATABASE"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  
  read -p "👉 Nhập tên database cần xóa: " dbname
  
  if [ -z "$dbname" ]; then
    log_error "Tên database không được để trống!"
    return 1
  fi
  
  if ! confirm "⚠️  Xác nhận xóa database '$dbname'?"; then
    log_info "Đã hủy"
    return 0
  fi
  
  read -p "👉 Nhập MySQL root password: " -s root_pass
  echo ""
  
  log_info "Đang xóa database..."
  
  mysql -uroot -p"$root_pass" <<EOF
DROP DATABASE IF EXISTS \`$dbname\`;
EOF
  
  if [ $? -eq 0 ]; then
    log_info "✅ Database '$dbname' đã được xóa"
    echo "$(date '+%Y-%m-%d %H:%M:%S') | DELETE DB | $dbname" >> "$BASE_DIR/logs/install.log"
  else
    log_error "Không thể xóa database! Kiểm tra password root."
  fi
}

# List all databases
list_db() {
  clear
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🗄️  DANH SÁCH DATABASE"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  
  read -p "👉 Nhập MySQL root password: " -s root_pass
  echo ""
  
  mysql -uroot -p"$root_pass" -e "SHOW DATABASES;" 2>/dev/null
  
  if [ $? -ne 0 ]; then
    log_error "Không thể kết nối! Kiểm tra password root."
  fi
  
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Export database
export_db() {
  clear
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "💾 EXPORT DATABASE"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  
  read -p "👉 Nhập tên database: " dbname
  read -p "👉 Nhập MySQL root password: " -s root_pass
  echo ""
  
  local backup_file="/opt/backups/mysql/${dbname}_$(date +%Y%m%d_%H%M%S).sql"
  mkdir -p /opt/backups/mysql
  
  log_info "Đang export database..."
  
  mysqldump -uroot -p"$root_pass" "$dbname" > "$backup_file" 2>/dev/null
  
  if [ $? -eq 0 ]; then
    gzip "$backup_file"
    log_info "✅ Đã export: ${backup_file}.gz"
  else
    log_error "Không thể export database!"
  fi
}
