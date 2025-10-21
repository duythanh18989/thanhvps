#!/bin/bash
# ========================================================
# 🚀 ThanhTV VPS Installer v2.0
# Mục tiêu: Cài môi trường Web Server (Nginx + PHP + MariaDB + Redis)
#            có giao diện quản lý (FileBrowser) & menu gum/whiptail
# ========================================================

set -e  # Exit on error
trap 'echo "❌ Error occurred at line $LINENO"; exit 1' ERR

# --- Kiểm tra quyền root ---
if [ "$EUID" -ne 0 ]; then
  echo "❌ Vui lòng chạy script bằng quyền root (sudo su)."
  exit 1
fi

# --- Đặt thư mục gốc của script ---
export BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
echo "BASE_DIR=$BASE_DIR"

# --- Load file utils (REQUIRED FIRST) ---
if [ ! -f "$BASE_DIR/functions/utils.sh" ]; then
  echo "❌ Không tìm thấy file utils.sh"
  exit 1
fi

source "$BASE_DIR/functions/utils.sh"

# --- Tạo thư mục logs ---
mkdir -p "$BASE_DIR/logs"

# --- In banner ---
clear
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 ThanhTV VPS Installer v2.0"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📅 $(date '+%Y-%m-%d %H:%M:%S')"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# --- Kiểm tra OS ---
check_os

# --- Load config.yml (dùng parser trong utils) ---
CONFIG_FILE="$BASE_DIR/config.yml"
if [ ! -f "$CONFIG_FILE" ]; then
  log_error "Không tìm thấy file config.yml"
  exit 1
fi

log_info "Đang load cấu hình từ config.yml..."
parse_yaml "$CONFIG_FILE" "CONFIG_"
log_info "✅ Đã load cấu hình"

# --- Cài gum (TUI framework) ---
check_gum

# --- Hỏi domain chính ---
echo ""
read -p "👉 Nhập domain chính cho website (Enter để dùng ${CONFIG_default_domain}): " MAIN_DOMAIN
MAIN_DOMAIN=${MAIN_DOMAIN:-${CONFIG_default_domain}}

# --- Random mật khẩu MySQL root ---
if [ -n "$CONFIG_mysql_root_password" ] && [ "$CONFIG_mysql_root_password" != '""' ]; then
  MYSQL_ROOT_PASS="$CONFIG_mysql_root_password"
else
  MYSQL_ROOT_PASS=$(random_password 16)
fi

echo "mysql_root_password=$MYSQL_ROOT_PASS" >> "$BASE_DIR/logs/install.log"

# --- Load các module cài đặt ---
log_info "Loading installation modules..."

for module in setup_nginx setup_php setup_mysql setup_redis setup_nodejs setup_filemanager setup_ssl; do
  if [ -f "$BASE_DIR/functions/${module}.sh" ]; then
    source "$BASE_DIR/functions/${module}.sh"
    log_debug "Loaded: ${module}.sh"
  else
    log_warn "Module not found: ${module}.sh"
  fi
done

# --- Bắt đầu cài đặt ---
echo ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "🚀 BẮT ĐẦU CÀI ĐẶT..."
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# System update
log_info "Cập nhật system packages..."
apt-get update -y &>/dev/null || log_warn "apt-get update có warning"

# Install core packages
log_info "Cài đặt dependencies cơ bản..."
apt-get install -y curl wget git zip unzip software-properties-common &>/dev/null

# Install components
echo ""
install_nginx "$MAIN_DOMAIN" || log_error "Nginx installation failed"

echo ""
install_php || log_error "PHP installation failed"

echo ""
install_mysql "$MYSQL_ROOT_PASS" || log_error "MySQL installation failed"

# Optional: Redis
if [ "${CONFIG_redis_enabled}" = "true" ]; then
  echo ""
  install_redis || log_warn "Redis installation failed (optional)"
fi

# Optional: NodeJS
if [ "${CONFIG_nodejs_enabled}" = "true" ]; then
  echo ""
  install_nodejs || log_warn "NodeJS installation failed (optional)"
fi

# Optional: File Manager
if [ "${CONFIG_filemanager_enabled}" = "true" ]; then
  echo ""
  install_filemanager || log_warn "FileBrowser installation failed (optional)"
fi

# Optional: SSL
if [ "${CONFIG_ssl_auto_ssl}" = "true" ]; then
  echo ""
  install_ssl "$MAIN_DOMAIN" || log_warn "SSL installation failed (optional)"
fi

# --- Tóm tắt kết quả ---
echo ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "🎉 CÀI ĐẶT HOÀN TẤT!"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 THÔNG TIN QUAN TRỌNG:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🌐 Domain: $MAIN_DOMAIN"
echo "🐘 PHP: ${CONFIG_php_versions} (default: ${CONFIG_default_php})"
echo "🗄️  MariaDB root: $MYSQL_ROOT_PASS"

if [ "${CONFIG_redis_enabled}" = "true" ] && command_exists redis-cli; then
  echo "� Redis: Đã cài đặt (port ${CONFIG_redis_port})"
fi

if [ "${CONFIG_nodejs_enabled}" = "true" ] && command_exists node; then
  echo "🟢 NodeJS: $(node -v)"
fi

if [ "${CONFIG_filemanager_enabled}" = "true" ] && service_is_active filebrowser; then
  local filebrowser_ip=$(hostname -I | awk '{print $1}')
  local filebrowser_port=${CONFIG_filemanager_port}
  echo "📂 File Manager: http://${filebrowser_ip}:${filebrowser_port}"
  
  # Get credentials from log
  local fb_user=$(grep "filebrowser_user=" "$BASE_DIR/logs/install.log" | tail -1 | cut -d'=' -f2)
  local fb_pass=$(grep "filebrowser_pass=" "$BASE_DIR/logs/install.log" | tail -1 | cut -d'=' -f2)
  echo "   User: $fb_user | Pass: $fb_pass"
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 Log file: $BASE_DIR/logs/install.log"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# --- Cài đặt command shortcut 'thanhvps' ---
log_info "Đang cài đặt command shortcut..."

if [ -f "$BASE_DIR/thanhvps" ]; then
  # Copy to /usr/local/bin
  cp "$BASE_DIR/thanhvps" /usr/local/bin/thanhvps
  chmod +x /usr/local/bin/thanhvps
  
  # Create symlink if not exists
  if [ ! -L /usr/bin/thanhvps ]; then
    ln -sf /usr/local/bin/thanhvps /usr/bin/thanhvps
  fi
  
  log_info "✅ Command 'thanhvps' đã được cài đặt"
  log_info "   Bạn có thể gọi: thanhvps (từ bất kỳ đâu)"
else
  log_warn "File thanhvps không tìm thấy, bỏ qua"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "💡 CÁCH SỬ DỤNG:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Gọi menu:        thanhvps"
echo "Thêm website:    thanhvps website add"
echo "Tạo database:    thanhvps db create"
echo "Xem status:      thanhvps info"
echo "Restart dịch vụ: thanhvps restart"
echo "Xem help:        thanhvps help"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# --- Hỏi có muốn vào menu không ---
echo ""
read -p "👉 Bạn có muốn vào menu quản lý ngay bây giờ? (y/n): " open_menu

if [[ "$open_menu" =~ ^[Yy]$ ]]; then
  source "$BASE_DIR/functions/menu.sh"
  main_menu
else
  echo ""
  log_info "Để mở menu sau này, chạy: thanhvps"
  log_info "Hoặc: bash $BASE_DIR/functions/menu.sh"
  echo ""
  log_info "🎉 Hoàn tất! Chúc bạn sử dụng vui vẻ!"
fi
