#!/bin/bash
# ========================================================
# 🗄️ setup_mysql.sh - Cài đặt MariaDB + set root password (cập nhật)
# ========================================================

install_mysql() {
  local MYSQL_PASS=$1

  log_info "Đang cài đặt MariaDB..."
  apt-get install -y mariadb-server >/dev/null

  systemctl enable mariadb
  systemctl start mariadb

  log_info "Đang thiết lập mật khẩu root..."

  # Chạy bằng sudo, chuyển sang mysql_native_password
  sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED VIA mysql_native_password USING PASSWORD('$MYSQL_PASS'); FLUSH PRIVILEGES;"

  log_info "✅ MariaDB đã cài đặt và đặt mật khẩu root."
}
