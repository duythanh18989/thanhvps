#!/bin/bash
# ========================================================
# 🗄️ setup_mysql.sh - Cài đặt MariaDB + set root password
# ========================================================

install_mysql() {
  local MYSQL_PASS=$1

  log_info "Đang cài đặt MariaDB..."
  apt-get install -y mariadb-server >/dev/null

  systemctl enable mariadb
  systemctl start mariadb

  # Đặt mật khẩu root
  mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_PASS'; FLUSH PRIVILEGES;"

  log_info "✅ MariaDB đã cài đặt và đặt mật khẩu root."
}
