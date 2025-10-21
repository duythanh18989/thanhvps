#!/bin/bash
# ======================================================
# MENU QUAN LY VPS (Giao dien GUM / WHIPTAIL)
# ------------------------------------------------------
# Tac gia: ThanhTV | Phien ban: 2.0
# Script ho tro menu quan ly Website, Database,
# Backup, He thong, Auto Update.
# ======================================================

# Set BASE_DIR correctly
if [ -z "$BASE_DIR" ]; then
  if [ -f "$(dirname "$(realpath "$0")")/../functions/utils.sh" ]; then
    # Called from functions directory
    BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  else
    # Called from root directory
    BASE_DIR="$(pwd)"
  fi
fi

LOG_FILE="/var/log/menu_vps.log"

# ------------------------------------------------------
# Load utils first (required for all modules)
# ------------------------------------------------------
if [ -f "$BASE_DIR/functions/utils.sh" ]; then
  source "$BASE_DIR/functions/utils.sh"
else
  echo "ERROR: Cannot find utils.sh"
  exit 1
fi

# ------------------------------------------------------
# Load all other function modules (exclude autoupdate.sh, backup.sh, and menu.sh itself)
# ------------------------------------------------------
for file in "$BASE_DIR"/functions/*.sh; do
  [ -f "$file" ] && \
  [ "$file" != "$BASE_DIR/functions/utils.sh" ] && \
  [ "$file" != "$BASE_DIR/functions/autoupdate.sh" ] && \
  [ "$file" != "$BASE_DIR/functions/backup.sh" ] && \
  [ "$file" != "$BASE_DIR/functions/menu.sh" ] && \
  source "$file"
done

# ------------------------------------------------------
# Kiem tra GUM (UI dep) hay fallback WHIPTAIL
# ------------------------------------------------------
use_gum=false
if command_exists gum; then
  use_gum=true
fi

# ------------------------------------------------------
# Main menu function
# ------------------------------------------------------
main_menu() {
  show_main_menu
}

# ------------------------------------------------------
# Menu chinh
# ------------------------------------------------------
show_main_menu() {
  if $use_gum; then
    clear
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🚀 ThanhTV VPS - MENU QUẢN LÝ"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Show system info
    if [ -f "$BASE_DIR/version.txt" ]; then
      echo "📦 Version: $(cat $BASE_DIR/version.txt)"
    fi
    
    # Show services status
    local nginx_status="❌"
    local php_status="❌"
    local mysql_status="❌"
    local redis_status="❌"
    
    command_exists nginx && service_is_active nginx && nginx_status="✅"
    command_exists php8.2-fpm && service_is_active php8.2-fpm && php_status="✅"
    command_exists mysql && service_is_active mariadb && mysql_status="✅"
    command_exists redis-server && service_is_active redis-server && redis_status="✅"
    
    echo "🔧 Services: Nginx $nginx_status | PHP $php_status | MySQL $mysql_status | Redis $redis_status"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    choice=$(gum choose \
      "1  🌐 Quản lý Website (Thêm/Xóa/List/SSL)" \
      "2  🗄️  Quản lý Database (Create/Delete/Export)" \
      "3  💾 Backup & Phục hồi" \
      "4  ⚙️  Quản trị Hệ thống (Restart/Monitor/Clean)" \
      "5  🐘 Quản lý PHP (Switch version/Config)" \
      "6  📁 File Manager (FileBrowser)" \
      "7  🔒 Quản lý SSL/HTTPS" \
      "8  🔄 Auto Update Script" \
      "9  📊 Thông tin VPS" \
      "0  🚪 Thoát")
  else
    choice=$(whiptail --title "Menu Quan Ly VPS" --menu "Chon chuc nang:" 25 80 15 \
      "1" "🌐 Quan ly Website" \
      "2" "🗄️  Quan ly Database" \
      "3" "💾 Backup & Phuc hoi" \
      "4" "⚙️  Quan tri He thong" \
      "5" "🐘 Quan ly PHP" \
      "6" "📁 File Manager" \
      "7" "🔒 Quan ly SSL" \
      "8" "🔄 Auto Update" \
      "9" "📊 Thong tin VPS" \
      "0" "🚪 Thoat" 3>&1 1>&2 2>&3)
  fi

  # Parse choice (extract number)
  local num=$(echo "$choice" | grep -o '^[0-9]*')
  
  case "$num" in
    1) show_website_menu ;;
    2) show_db_menu ;;
    3) show_backup_menu ;;
    4) show_system_menu ;;
    5) show_php_menu ;;
    6) show_filemanager_menu ;;
    7) show_ssl_menu ;;
    8) bash "$BASE_DIR/functions/autoupdate.sh"; read -p "Press Enter to continue..."; show_main_menu ;;
    9) show_info_menu ;;
    0|"") echo "Tam biet!"; exit 0 ;;
    *) log_error "Lua chon khong hop le!"; sleep 1; show_main_menu ;;
  esac
}

# ------------------------------------------------------
# Menu con: Quan ly Website
# ------------------------------------------------------
show_website_menu() {
  if $use_gum; then
    clear
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🌐 QUẢN LÝ WEBSITE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    choice=$(gum choose \
      "1  Them website moi" \
      "2  Xoa website" \
      "3  Danh sach website" \
      "4  Xem log website" \
      "5  Restart Nginx/PHP" \
      "6  Quay lai")
  else
    choice=$(whiptail --title "Quan ly Website" --menu "Chon tac vu:" 20 70 10 \
      "1" "Them website moi" \
      "2" "Xoa website" \
      "3" "Danh sach website" \
      "4" "Xem log website" \
      "5" "Restart Nginx/PHP" \
      "6" "Quay lai" 3>&1 1>&2 2>&3)
  fi

  local num=$(echo "$choice" | grep -o '^[0-9]*')
  
  case "$num" in
    1) add_website; read -p "Press Enter to continue..."; show_website_menu ;;
    2) remove_website; read -p "Press Enter to continue..."; show_website_menu ;;
    3) list_websites; read -p "Press Enter to continue..."; show_website_menu ;;
    4) view_logs; show_website_menu ;;
    5) restart_nginx_php; read -p "Press Enter to continue..."; show_website_menu ;;
    6|"") show_main_menu ;;
    *) log_error "Lua chon khong hop le!"; sleep 1; show_website_menu ;;
  esac
}

# ------------------------------------------------------
# Menu con: Database
# ------------------------------------------------------
show_db_menu() {
  if $use_gum; then
    clear
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🗄️  QUẢN LÝ DATABASE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    choice=$(gum choose \
      "1  Tao database moi" \
      "2  Xoa database" \
      "3  Danh sach database" \
      "4  Export database" \
      "5  Quay lai")
  else
    choice=$(whiptail --title "Quan ly Database" --menu "Chon tac vu:" 20 70 10 \
      "1" "Tao database moi" \
      "2" "Xoa database" \
      "3" "Danh sach database" \
      "4" "Export database" \
      "5" "Quay lai" 3>&1 1>&2 2>&3)
  fi

  local num=$(echo "$choice" | grep -o '^[0-9]*')
  
  case "$num" in
    1) create_db; read -p "Press Enter to continue..."; show_db_menu ;;
    2) delete_db; read -p "Press Enter to continue..."; show_db_menu ;;
    3) list_db; read -p "Press Enter to continue..."; show_db_menu ;;
    4) export_db; read -p "Press Enter to continue..."; show_db_menu ;;
    5|"") show_main_menu ;;
    *) log_error "Lua chon khong hop le!"; sleep 1; show_db_menu ;;
  esac
}

# ------------------------------------------------------
# Menu: Backup
# ------------------------------------------------------
show_backup_menu() {
  clear
  bash "$BASE_DIR/functions/backup.sh"
  read -p "Press Enter to continue..."
  show_main_menu
}

# ------------------------------------------------------
# Menu: System
# ------------------------------------------------------
show_system_menu() {
  if $use_gum; then
    clear
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "⚙️  QUẢN TRỊ HỆ THỐNG"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    choice=$(gum choose \
      "1  Restart tất cả services" \
      "2  Monitor tài nguyên (CPU/RAM/Disk)" \
      "3  Dọn dẹp cache/log" \
      "4  Cấu hình Firewall (UFW)" \
      "5  Cài đặt Redis Cache" \
      "6  Cài đặt NodeJS/PM2" \
      "7  Quay lại")
  else
    choice=$(whiptail --title "Quan tri He thong" --menu "Chon tac vu:" 20 70 10 \
      "1" "Restart services" \
      "2" "Monitor tai nguyen" \
      "3" "Don dep cache/log" \
      "4" "Cau hinh Firewall" \
      "5" "Cai dat Redis" \
      "6" "Cai dat NodeJS" \
      "7" "Quay lai" 3>&1 1>&2 2>&3)
  fi

  local num=$(echo "$choice" | grep -o '^[0-9]*')
  
  case "$num" in
    1) restart_all_services; read -p "Press Enter to continue..."; show_system_menu ;;
    2) show_system_monitor; read -p "Press Enter to continue..."; show_system_menu ;;
    3) clean_system; read -p "Press Enter to continue..."; show_system_menu ;;
    4) configure_firewall; read -p "Press Enter to continue..."; show_system_menu ;;
    5) install_redis; read -p "Press Enter to continue..."; show_system_menu ;;
    6) install_nodejs; read -p "Press Enter to continue..."; show_system_menu ;;
    7|"") show_main_menu ;;
    *) log_error "Lua chon khong hop le!"; sleep 1; show_system_menu ;;
  esac
}

# ------------------------------------------------------
# Menu: PHP Management
# ------------------------------------------------------
show_php_menu() {
  if $use_gum; then
    clear
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🐘 QUẢN LÝ PHP"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Show current PHP versions
    echo "📦 PHP versions installed:"
    for ver in 7.4 8.1 8.2 8.3; do
      if command_exists php$ver; then
        if service_is_active php$ver-fpm; then
          echo "  ✅ PHP $ver (running)"
        else
          echo "  ⚠️  PHP $ver (stopped)"
        fi
      fi
    done
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    choice=$(gum choose \
      "1  Cài đặt PHP version mới" \
      "2  Restart PHP-FPM services" \
      "3  Cấu hình php.ini" \
      "4  Xem PHP info" \
      "5  Quay lại")
  else
    choice=$(whiptail --title "Quan ly PHP" --menu "Chon tac vu:" 20 70 10 \
      "1" "Cai dat PHP version" \
      "2" "Restart PHP-FPM" \
      "3" "Cau hinh php.ini" \
      "4" "Xem PHP info" \
      "5" "Quay lai" 3>&1 1>&2 2>&3)
  fi

  local num=$(echo "$choice" | grep -o '^[0-9]*')
  
  case "$num" in
    1) install_php_version; read -p "Press Enter to continue..."; show_php_menu ;;
    2) restart_php_services; read -p "Press Enter to continue..."; show_php_menu ;;
    3) configure_php_ini; read -p "Press Enter to continue..."; show_php_menu ;;
    4) show_php_info; read -p "Press Enter to continue..."; show_php_menu ;;
    5|"") show_main_menu ;;
    *) log_error "Lua chon khong hop le!"; sleep 1; show_php_menu ;;
  esac
}

# ------------------------------------------------------
# Menu: File Manager
# ------------------------------------------------------
show_filemanager_menu() {
  if $use_gum; then
    clear
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📁 FILE MANAGER (FileBrowser)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if service_is_active filebrowser; then
      local fb_ip=$(hostname -I | awk '{print $1}')
      local fb_port=${CONFIG_filemanager_port:-8080}
      echo "✅ FileBrowser đang chạy"
      echo "🌐 URL: http://${fb_ip}:${fb_port}"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    else
      echo "❌ FileBrowser chưa cài đặt hoặc đã dừng"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    fi
    
    choice=$(gum choose \
      "1  Cài đặt FileBrowser" \
      "2  Start/Stop FileBrowser" \
      "3  Thêm user mới" \
      "4  Đổi mật khẩu admin" \
      "5  Xem thông tin truy cập" \
      "6  Quay lại")
  else
    choice=$(whiptail --title "File Manager" --menu "Chon tac vu:" 20 70 10 \
      "1" "Cai dat FileBrowser" \
      "2" "Start/Stop service" \
      "3" "Them user moi" \
      "4" "Doi mat khau" \
      "5" "Xem thong tin" \
      "6" "Quay lai" 3>&1 1>&2 2>&3)
  fi

  local num=$(echo "$choice" | grep -o '^[0-9]*')
  
  case "$num" in
    1) install_filemanager; read -p "Press Enter to continue..."; show_filemanager_menu ;;
    2) toggle_filemanager; read -p "Press Enter to continue..."; show_filemanager_menu ;;
    3) add_filemanager_user; read -p "Press Enter to continue..."; show_filemanager_menu ;;
    4) change_filemanager_password; read -p "Press Enter to continue..."; show_filemanager_menu ;;
    5) show_filemanager_info; read -p "Press Enter to continue..."; show_filemanager_menu ;;
    6|"") show_main_menu ;;
    *) log_error "Lua chon khong hop le!"; sleep 1; show_filemanager_menu ;;
  esac
}

# ------------------------------------------------------
# Menu: SSL Management
# ------------------------------------------------------
show_ssl_menu() {
  if $use_gum; then
    clear
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔒 QUẢN LÝ SSL/HTTPS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    choice=$(gum choose \
      "1  Cài SSL cho domain (Let's Encrypt)" \
      "2  Gia hạn SSL (renew)" \
      "3  Xóa SSL certificate" \
      "4  Kiểm tra SSL expiry" \
      "5  Cài auto-renew SSL" \
      "6  Quay lại")
  else
    choice=$(whiptail --title "Quan ly SSL" --menu "Chon tac vu:" 20 70 10 \
      "1" "Cai SSL cho domain" \
      "2" "Gia han SSL" \
      "3" "Xoa SSL" \
      "4" "Kiem tra SSL" \
      "5" "Cai auto-renew" \
      "6" "Quay lai" 3>&1 1>&2 2>&3)
  fi

  local num=$(echo "$choice" | grep -o '^[0-9]*')
  
  case "$num" in
    1) install_ssl; read -p "Press Enter to continue..."; show_ssl_menu ;;
    2) renew_ssl; read -p "Press Enter to continue..."; show_ssl_menu ;;
    3) remove_ssl; read -p "Press Enter to continue..."; show_ssl_menu ;;
    4) check_ssl_expiry; read -p "Press Enter to continue..."; show_ssl_menu ;;
    5) setup_ssl_autorenew; read -p "Press Enter to continue..."; show_ssl_menu ;;
    6|"") show_main_menu ;;
    *) log_error "Lua chon khong hop le!"; sleep 1; show_ssl_menu ;;
  esac
}

# ------------------------------------------------------
# Menu: VPS Info
# ------------------------------------------------------
show_info_menu() {
  clear
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📊 THÔNG TIN VPS"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  # Version
  if [ -f "$BASE_DIR/version.txt" ]; then
    echo "📦 ThanhTV VPS Version: $(cat $BASE_DIR/version.txt)"
  fi
  echo "📂 Installation Path: $BASE_DIR"
  echo ""
  
  # System info
  echo "🖥️  System Information:"
  echo "  OS: $(lsb_release -d | cut -f2)"
  echo "  Kernel: $(uname -r)"
  echo "  Hostname: $(hostname)"
  echo "  IP: $(hostname -I | awk '{print $1}')"
  echo ""
  
  # Resources
  echo "💾 Resources:"
  echo "  CPU: $(nproc) cores"
  echo "  RAM: $(free -h | awk '/^Mem:/ {print $2}') total, $(free -h | awk '/^Mem:/ {print $3}') used"
  echo "  Disk: $(df -h / | awk 'NR==2 {print $2}') total, $(df -h / | awk 'NR==2 {print $3}') used"
  echo ""
  
  # Services
  echo "🔧 Services Status:"
  
  if command_exists nginx; then
    if service_is_active nginx; then
      echo "  ✅ Nginx: Running ($(nginx -v 2>&1 | cut -d'/' -f2))"
    else
      echo "  ❌ Nginx: Stopped"
    fi
  else
    echo "  ⚠️  Nginx: Not installed"
  fi
  
  # PHP versions
  local php_found=false
  for ver in 7.4 8.1 8.2 8.3; do
    if command_exists php$ver; then
      php_found=true
      if service_is_active php$ver-fpm; then
        echo "  ✅ PHP $ver: Running"
      else
        echo "  ❌ PHP $ver: Stopped"
      fi
    fi
  done
  
  if [ "$php_found" = false ]; then
    echo "  ⚠️  PHP: Not installed"
  fi
  
  if command_exists mysql; then
    if service_is_active mariadb; then
      echo "  ✅ MariaDB: Running ($(mysql --version | awk '{print $5}' | cut -d'-' -f1))"
    else
      echo "  ❌ MariaDB: Stopped"
    fi
  else
    echo "  ⚠️  MariaDB: Not installed"
  fi
  
  if command_exists redis-server; then
    if service_is_active redis-server; then
      echo "  ✅ Redis: Running"
    else
      echo "  ❌ Redis: Stopped"
    fi
  else
    echo "  ⚠️  Redis: Not installed"
  fi
  
  if command_exists node; then
    echo "  ✅ NodeJS: $(node -v)"
  else
    echo "  ⚠️  NodeJS: Not installed"
  fi
  
  if command_exists filebrowser; then
    if service_is_active filebrowser; then
      local fb_ip=$(hostname -I | awk '{print $1}')
      local fb_port=${CONFIG_filemanager_port:-8080}
      echo "  ✅ FileBrowser: Running at http://${fb_ip}:${fb_port}"
    else
      echo "  ❌ FileBrowser: Stopped"
    fi
  else
    echo "  ⚠️  FileBrowser: Not installed"
  fi
  
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  
  read -p "Press Enter to continue..."
  show_main_menu
}

# ------------------------------------------------------
# Helper Functions
# ------------------------------------------------------

# Restart all services
restart_all_services() {
  log_info "Restarting all services..."
  
  systemctl restart nginx 2>/dev/null && log_info "✅ Nginx restarted"
  
  for php_ver in 7.4 8.1 8.2 8.3; do
    if systemctl is-enabled "php${php_ver}-fpm" &>/dev/null; then
      systemctl restart "php${php_ver}-fpm" 2>/dev/null && log_info "✅ PHP ${php_ver} restarted"
    fi
  done
  
  systemctl restart mariadb 2>/dev/null && log_info "✅ MariaDB restarted"
  systemctl restart redis-server 2>/dev/null && log_info "✅ Redis restarted"
  
  log_info "🎉 All services restarted!"
}

# System monitor
show_system_monitor() {
  clear
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📊 SYSTEM MONITOR"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  echo "💻 CPU Usage:"
  top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print "  Used: " 100 - $1"%"}'
  echo ""
  
  echo "💾 Memory Usage:"
  free -h
  echo ""
  
  echo "💿 Disk Usage:"
  df -h / /var /home 2>/dev/null
  echo ""
  
  echo "🌐 Network Connections:"
  ss -tuln | grep LISTEN | head -10
  echo ""
  
  echo "🔥 Top Processes:"
  ps aux --sort=-%mem | head -6
}

# Clean system
clean_system() {
  log_info "Cleaning system..."
  
  # Clean apt cache
  apt-get clean
  apt-get autoclean
  apt-get autoremove -y
  
  # Clean old logs (keep last 7 days)
  find /var/log -type f -name "*.log" -mtime +7 -delete 2>/dev/null
  find /var/log -type f -name "*.gz" -delete 2>/dev/null
  
  # Clean PHP sessions older than 24h
  find /var/lib/php/sessions -type f -mtime +1 -delete 2>/dev/null
  
  log_info "✅ System cleaned!"
}

# Configure firewall
configure_firewall() {
  if ! command_exists ufw; then
    log_info "Installing UFW..."
    apt-get install -y ufw
  fi
  
  log_info "Configuring firewall..."
  
  ufw --force enable
  ufw default deny incoming
  ufw default allow outgoing
  
  # Allow essential ports
  ufw allow 22/tcp    # SSH
  ufw allow 80/tcp    # HTTP
  ufw allow 443/tcp   # HTTPS
  
  # Allow custom ports if configured
  if [ -n "${CONFIG_filemanager_port}" ]; then
    ufw allow ${CONFIG_filemanager_port}/tcp  # FileBrowser
  fi
  
  ufw status
  log_info "✅ Firewall configured!"
}

# Install/manage PHP version
install_php_version() {
  if $use_gum; then
    php_ver=$(gum choose "7.4" "8.1" "8.2" "8.3")
  else
    php_ver=$(whiptail --inputbox "Enter PHP version (7.4, 8.1, 8.2, 8.3):" 10 60 "8.2" 3>&1 1>&2 2>&3)
  fi
  
  if [ -n "$php_ver" ]; then
    log_info "Installing PHP $php_ver..."
    bash "$BASE_DIR/functions/setup_php.sh"
    install_php "$php_ver"
  fi
}

# Restart PHP services
restart_php_services() {
  for php_ver in 7.4 8.1 8.2 8.3; do
    if systemctl is-enabled "php${php_ver}-fpm" &>/dev/null; then
      systemctl restart "php${php_ver}-fpm" && log_info "✅ PHP ${php_ver}-fpm restarted"
    fi
  done
}

# Configure php.ini
configure_php_ini() {
  if $use_gum; then
    php_ver=$(gum choose "7.4" "8.1" "8.2" "8.3")
  else
    php_ver=$(whiptail --inputbox "Enter PHP version:" 10 60 "8.2" 3>&1 1>&2 2>&3)
  fi
  
  if [ -n "$php_ver" ]; then
    local php_ini="/etc/php/$php_ver/fpm/php.ini"
    if [ -f "$php_ini" ]; then
      ${EDITOR:-nano} "$php_ini"
      systemctl restart "php${php_ver}-fpm"
      log_info "✅ PHP $php_ver configured and restarted"
    else
      log_error "❌ php.ini not found for PHP $php_ver"
    fi
  fi
}

# Show PHP info
show_php_info() {
  clear
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🐘 PHP INFORMATION"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  for ver in 7.4 8.1 8.2 8.3; do
    if command_exists php$ver; then
      echo "📦 PHP $ver:"
      php$ver -v | head -1
      echo "  Config: $(php$ver --ini | grep "Loaded Configuration" | cut -d':' -f2 | xargs)"
      echo ""
    fi
  done
}

# FileBrowser functions
install_filemanager() {
  bash "$BASE_DIR/functions/setup_filemanager.sh"
}

toggle_filemanager() {
  if service_is_active filebrowser; then
    systemctl stop filebrowser
    log_info "✅ FileBrowser stopped"
  else
    systemctl start filebrowser
    log_info "✅ FileBrowser started"
  fi
}

add_filemanager_user() {
  if $use_gum; then
    username=$(gum input --placeholder "Username")
    password=$(gum input --password --placeholder "Password")
  else
    read -p "Username: " username
    read -sp "Password: " password
    echo ""
  fi
  
  if [ -n "$username" ] && [ -n "$password" ]; then
    filebrowser users add "$username" "$password" --database /etc/filebrowser/filebrowser.db
    log_info "✅ User $username added"
  fi
}

change_filemanager_password() {
  if $use_gum; then
    username=$(gum input --placeholder "Username" --value "admin")
    password=$(gum input --password --placeholder "New Password")
  else
    read -p "Username [admin]: " username
    username=${username:-admin}
    read -sp "New Password: " password
    echo ""
  fi
  
  if [ -n "$password" ]; then
    filebrowser users update "$username" --password "$password" --database /etc/filebrowser/filebrowser.db
    log_info "✅ Password updated for $username"
  fi
}

show_filemanager_info() {
  clear
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📁 FILE BROWSER INFO"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  
  if service_is_active filebrowser; then
    local fb_ip=$(hostname -I | awk '{print $1}')
    local fb_port=${CONFIG_filemanager_port:-8080}
    echo "✅ Status: Running"
    echo "🌐 URL: http://${fb_ip}:${fb_port}"
    echo ""
    echo "👤 Users:"
    filebrowser users ls --database /etc/filebrowser/filebrowser.db 2>/dev/null || echo "  Cannot list users"
  else
    echo "❌ FileBrowser is not running"
  fi
  echo ""
}

# SSL functions (delegates to setup_ssl.sh)
install_ssl() {
  bash "$BASE_DIR/functions/setup_ssl.sh"
  setup_ssl
}

renew_ssl() {
  certbot renew
  log_info "✅ SSL certificates renewed"
}

remove_ssl() {
  if $use_gum; then
    domain=$(gum input --placeholder "Domain name")
  else
    read -p "Domain name: " domain
  fi
  
  if [ -n "$domain" ]; then
    certbot delete --cert-name "$domain"
    log_info "✅ SSL removed for $domain"
  fi
}

check_ssl_expiry() {
  certbot certificates
}

setup_ssl_autorenew() {
  # Add cron job for auto-renewal
  if ! crontab -l | grep -q "certbot renew"; then
    (crontab -l 2>/dev/null; echo "0 0 * * * certbot renew --quiet") | crontab -
    log_info "✅ Auto-renew SSL configured (runs daily at midnight)"
  else
    log_info "ℹ️  Auto-renew already configured"
  fi
}

# View logs
view_logs() {
  if $use_gum; then
    choice=$(gum choose "Nginx Error Log" "Nginx Access Log" "PHP-FPM Log" "MariaDB Log")
  else
    choice=$(whiptail --menu "Select log file:" 15 60 4 \
      "1" "Nginx Error Log" \
      "2" "Nginx Access Log" \
      "3" "PHP-FPM Log" \
      "4" "MariaDB Log" 3>&1 1>&2 2>&3)
  fi
  
  case "$choice" in
    *"Nginx Error"*|"1") tail -f /var/log/nginx/error.log ;;
    *"Nginx Access"*|"2") tail -f /var/log/nginx/access.log ;;
    *"PHP"*|"3") tail -f /var/log/php8.2-fpm.log ;;
    *"MariaDB"*|"4") tail -f /var/log/mysql/error.log ;;
  esac
}

# Restart Nginx/PHP
restart_nginx_php() {
  systemctl restart nginx && log_info "✅ Nginx restarted"
  
  for ver in 7.4 8.1 8.2 8.3; do
    if systemctl is-enabled "php${ver}-fpm" &>/dev/null; then
      systemctl restart "php${ver}-fpm" && log_info "✅ PHP ${ver} restarted"
    fi
  done
}

# ------------------------------------------------------
# Chay menu chinh - only if called directly
# ------------------------------------------------------
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  while true; do
    show_main_menu
  done
fi
