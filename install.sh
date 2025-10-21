#!/bin/bash
# ========================================================
# 🚀 ThanhTV VPS Installer v1
# Mục tiêu: Cài môi trường Web Server (Nginx + PHP + MariaDB)
#            có giao diện quản lý (FileBrowser) & menu gum/whiptail
# ========================================================

# --- Kiểm tra quyền root ---
if [ "$EUID" -ne 0 ]; then
  echo "❌ Vui lòng chạy script bằng quyền root (sudo su)."
  exit 1
fi

# --- Đặt thư mục gốc của script ---
BASE_DIR=$(cd "$(dirname "$0")" && pwd)

# --- Load file utils ---
source "$BASE_DIR/functions/utils.sh"

# --- Load config.yml (dùng parser nhẹ trong utils) ---
CONFIG_FILE="$BASE_DIR/config.yml"
if [ ! -f "$CONFIG_FILE" ]; then
  echo "❌ Không tìm thấy file config.yml, vui lòng kiểm tra."
  exit 1
fi

parse_yaml "$CONFIG_FILE" "CONFIG_"
echo "✅ Đã load cấu hình mặc định từ config.yml"

# --- Kiểm tra OS ---
#check_os

# --- Cài gum (nếu có thể) ---
check_gum

# --- Tạo thư mục logs ---
mkdir -p "$BASE_DIR/logs"

# --- In banner ---
echo "============================================"
echo " 🌐 ThanhTV VPS Installer v1"
echo "============================================"

# --- Hỏi domain chính ---
read -p "Nhập domain chính cho website (Enter để dùng ${CONFIG_default_domain}): " MAIN_DOMAIN
MAIN_DOMAIN=${MAIN_DOMAIN:-${CONFIG_default_domain}}

# --- Random mật khẩu MySQL root ---
MYSQL_ROOT_PASS=$(random_password)
echo "mysql_root_password=$MYSQL_ROOT_PASS" >> "$BASE_DIR/logs/install.log"

# --- Gọi các module cài đặt ---
source "$BASE_DIR/functions/setup_nginx.sh"
source "$BASE_DIR/functions/setup_php.sh"
source "$BASE_DIR/functions/setup_mysql.sh"
source "$BASE_DIR/functions/setup_filemanager.sh"
source "$BASE_DIR/functions/setup_ssl.sh"

install_nginx "$MAIN_DOMAIN"
install_php
install_mysql "$MYSQL_ROOT_PASS"
install_filemanager
install_ssl "$MAIN_DOMAIN"

# --- Gọi menu chính sau khi setup xong ---
source "$BASE_DIR/functions/menu.sh"
main_menu

# --- In bảng tóm tắt ---
echo "============================================"
echo "🎉 Cài đặt hoàn tất!"
echo "--------------------------------------------"
echo "🌐 Domain: $MAIN_DOMAIN"
echo "🐘 PHP: ${CONFIG_php_versions}"
echo "🗄️  MariaDB root: $MYSQL_ROOT_PASS"
echo "📂 File Manager: http://$(hostname -I | awk '{print $1}'):${CONFIG_filemanager_port}"
echo "============================================"
