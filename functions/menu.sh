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
    service_is_active php8.2-fpm && php_status="✅"
    command_exists mysql && service_is_active mariadb && mysql_status="✅"
    command_exists redis-server && service_is_active redis-server && redis_status="✅"
    
    echo "🔧 Services: Nginx $nginx_status | PHP $php_status | MySQL $mysql_status | Redis $redis_status"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    choice=$(gum choose \
      "1  🌐 Quản lý Website (Thêm/Xóa/List/SSL)" \
      "2  🗄️  Quản lý Database (Create/Delete/Export)" \
      "3  � Deploy Website (NodeJS/PHP Quick)" \
      "4  �💾 Backup & Phục hồi" \
      "5  ⚙️  Quản trị Hệ thống (Restart/Monitor/Clean)" \
      "6  🐘 Quản lý PHP (Switch version/Config)" \
      "7  📁 File Manager (FileBrowser)" \
      "8  🔒 Quản lý SSL/HTTPS" \
      "9  🔄 Auto Update Script" \
      "I  📊 Thông tin VPS" \
      "0  🚪 Thoát")
  else
    choice=$(whiptail --title "Menu Quan Ly VPS" --menu "Chon chuc nang:" 25 80 15 \
      "1" "🌐 Quan ly Website" \
      "2" "🗄️  Quan ly Database" \
      "3" "� Deploy Website" \
      "4" "�💾 Backup & Phuc hoi" \
      "5" "⚙️  Quan tri He thong" \
      "6" "🐘 Quan ly PHP" \
      "7" "📁 File Manager" \
      "8" "🔒 Quan ly SSL" \
      "9" "🔄 Auto Update" \
      "I" "📊 Thong tin VPS" \
      "0" "🚪 Thoat" 3>&1 1>&2 2>&3)
  fi

  # Parse choice (extract number)
  local num=$(echo "$choice" | grep -o '^[0-9IiIi]*' | tr '[:lower:]' '[:upper:]')
  
  case "$num" in
    1) show_website_menu ;;
    2) show_db_menu ;;
    3) show_deploy_menu ;;
    4) show_backup_menu ;;
    5) show_system_menu ;;
    6) show_php_menu ;;
    7) show_filemanager_menu ;;
    8) show_ssl_menu ;;
    9) bash "$BASE_DIR/functions/autoupdate.sh"; read -p "Press Enter to continue..."; show_main_menu ;;
    I) show_info_menu ;;
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
      "4  Bao mat URL bang password" \
      "5  Xoa bao mat URL" \
      "6  Xem log website" \
      "7  Restart Nginx/PHP" \
      "8  Quay lai")
  else
    choice=$(whiptail --title "Quan ly Website" --menu "Chon tac vu:" 22 70 12 \
      "1" "Them website moi" \
      "2" "Xoa website" \
      "3" "Danh sach website" \
      "4" "Bao mat URL bang password" \
      "5" "Xoa bao mat URL" \
      "6" "Xem log website" \
      "7" "Restart Nginx/PHP" \
      "8" "Quay lai" 3>&1 1>&2 2>&3)
  fi

  local num=$(echo "$choice" | grep -o '^[0-9]*')
  
  case "$num" in
    1) add_website; read -p "Press Enter to continue..."; show_website_menu ;;
    2) remove_website; read -p "Press Enter to continue..."; show_website_menu ;;
    3) list_websites; read -p "Press Enter to continue..."; show_website_menu ;;
    4) protect_url_with_password; read -p "Press Enter to continue..."; show_website_menu ;;
    5) remove_url_password; read -p "Press Enter to continue..."; show_website_menu ;;
    6) view_logs; show_website_menu ;;
    7) restart_nginx_php; read -p "Press Enter to continue..."; show_website_menu ;;
    8|"") show_main_menu ;;
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
      "5  Cai dat phpMyAdmin" \
      "6  Xem thong tin phpMyAdmin" \
      "7  Danh sach MySQL users" \
      "8  Doi mat khau MySQL user" \
      "9  Restart MySQL/MariaDB service" \
      "R  Reset mat khau MySQL root (Recovery)" \
      "0  Quay lai")
  else
    choice=$(whiptail --title "Quan ly Database" --menu "Chon tac vu:" 22 70 13 \
      "1" "Tao database moi" \
      "2" "Xoa database" \
      "3" "Danh sach database" \
      "4" "Export database" \
      "5" "Cai dat phpMyAdmin" \
      "6" "Xem thong tin phpMyAdmin" \
      "7" "Danh sach MySQL users" \
      "8" "Doi mat khau MySQL user" \
      "9" "Restart MySQL/MariaDB service" \
      "R" "Reset mat khau MySQL root (Recovery)" \
      "0" "Quay lai" 3>&1 1>&2 2>&3)
  fi

  local num=$(echo "$choice" | grep -o '^[0-9RrRr]*' | tr '[:lower:]' '[:upper:]')
  
  case "$num" in
    1) create_db; read -p "Press Enter to continue..."; show_db_menu ;;
    2) delete_db; read -p "Press Enter to continue..."; show_db_menu ;;
    3) list_db; read -p "Press Enter to continue..."; show_db_menu ;;
    4) export_db; read -p "Press Enter to continue..."; show_db_menu ;;
    5) install_phpmyadmin_menu; read -p "Press Enter to continue..."; show_db_menu ;;
    6) show_phpmyadmin_info; read -p "Press Enter to continue..."; show_db_menu ;;
    7) list_mysql_users; read -p "Press Enter to continue..."; show_db_menu ;;
    8) change_mysql_password; read -p "Press Enter to continue..."; show_db_menu ;;
    9) restart_mysql_service; read -p "Press Enter to continue..."; show_db_menu ;;
    R) reset_mysql_root_password; read -p "Press Enter to continue..."; show_db_menu ;;
    0|"") show_main_menu ;;
    *) log_error "Lua chon khong hop le!"; sleep 1; show_db_menu ;;
  esac
}

# ------------------------------------------------------
# Menu: Backup
# ------------------------------------------------------
# Menu: Deploy Website
# ------------------------------------------------------
show_deploy_menu() {
  if $use_gum; then
    clear
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🚀 DEPLOY WEBSITE NHANH"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    choice=$(gum choose \
      "1  Deploy NodeJS App (Express/NestJS/Next.js)" \
      "2  Deploy PHP Website (Laravel/WordPress)" \
      "3  Danh sach websites da deploy" \
      "4  Them alias/domain phu cho site" \
      "5  Doi PHP version cho site" \
      "6  Fix permissions cho website" \
      "7  Xoa website da deploy" \
      "8  Quan ly NodeJS (PM2/Versions)" \
      "9  Quay lai")
  else
    choice=$(whiptail --title "Deploy Website" --menu "Chon loai:" 22 70 12 \
      "1" "Deploy NodeJS App" \
      "2" "Deploy PHP Website" \
      "3" "Danh sach websites" \
      "4" "Them alias/domain phu" \
      "5" "Doi PHP version" \
      "6" "Fix permissions" \
      "7" "Xoa website" \
      "8" "Quan ly NodeJS" \
      "9" "Quay lai" 3>&1 1>&2 2>&3)
  fi

  local num=$(echo "$choice" | grep -o '^[0-9]*')
  
  case "$num" in
    1) deploy_nodejs_app; read -p "Press Enter to continue..."; show_deploy_menu ;;
    2) deploy_php_website; read -p "Press Enter to continue..."; show_deploy_menu ;;
    3) list_deployed_sites; read -p "Press Enter to continue..."; show_deploy_menu ;;
    4) add_site_alias; read -p "Press Enter to continue..."; show_deploy_menu ;;
    5) change_site_php_version; read -p "Press Enter to continue..."; show_deploy_menu ;;
    6) fix_site_permissions; read -p "Press Enter to continue..."; show_deploy_menu ;;
    7) remove_deployed_site; read -p "Press Enter to continue..."; show_deploy_menu ;;
    8) show_nodejs_menu; show_deploy_menu ;;
    9|"") show_main_menu ;;
    *) log_error "Lua chon khong hop le!"; sleep 1; show_deploy_menu ;;
  esac
}

# ------------------------------------------------------
# Menu: NodeJS Management
# ------------------------------------------------------
show_nodejs_menu() {
  if $use_gum; then
    clear
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🟢 QUẢN LÝ NODEJS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Show NodeJS info if installed
    if command_exists node; then
      echo "📦 Node: $(node -v) | NPM: $(npm -v)"
      if command_exists pm2; then
        echo "🔧 PM2: $(pm2 -v)"
      fi
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    fi
    
    choice=$(gum choose \
      "1  Cai dat NodeJS/NVM/PM2" \
      "2  Quan ly PM2 Apps (Start/Stop/Restart/Logs)" \
      "3  Quan ly Node Versions (Install/Remove)" \
      "4  Xem thong tin NodeJS" \
      "5  Quay lai")
  else
    choice=$(whiptail --title "Quan ly NodeJS" --menu "Chon tac vu:" 20 70 10 \
      "1" "Cai dat NodeJS" \
      "2" "Quan ly PM2 Apps" \
      "3" "Quan ly Node Versions" \
      "4" "Xem thong tin" \
      "5" "Quay lai" 3>&1 1>&2 2>&3)
  fi

  local num=$(echo "$choice" | grep -o '^[0-9]*')
  
  case "$num" in
    1) install_nodejs; read -p "Press Enter to continue..."; show_nodejs_menu ;;
    2) manage_pm2_apps; read -p "Press Enter to continue..."; show_nodejs_menu ;;
    3) manage_node_versions; read -p "Press Enter to continue..."; show_nodejs_menu ;;
    4) nodejs_info; read -p "Press Enter to continue..."; show_nodejs_menu ;;
    5|"") return 0 ;;
    *) log_error "Lua chon khong hop le!"; sleep 1; show_nodejs_menu ;;
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
      "6  Quay lại")
  else
    choice=$(whiptail --title "Quan tri He thong" --menu "Chon tac vu:" 20 70 10 \
      "1" "Restart services" \
      "2" "Monitor tai nguyen" \
      "3" "Don dep cache/log" \
      "4" "Cau hinh Firewall" \
      "5" "Cai dat Redis" \
      "6" "Quay lai" 3>&1 1>&2 2>&3)
  fi

  local num=$(echo "$choice" | grep -o '^[0-9]*')
  
  case "$num" in
    1) restart_all_services; read -p "Press Enter to continue..."; show_system_menu ;;
    2) show_system_monitor; read -p "Press Enter to continue..."; show_system_menu ;;
    3) clean_system; read -p "Press Enter to continue..."; show_system_menu ;;
    4) configure_firewall; read -p "Press Enter to continue..."; show_system_menu ;;
    5) install_redis; read -p "Press Enter to continue..."; show_system_menu ;;
    6|"") show_main_menu ;;
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
      "5  Fix permissions (chuyển sang www-data)" \
      "6  Xem thông tin truy cập" \
      "7  Quay lại")
  else
    choice=$(whiptail --title "File Manager" --menu "Chon tac vu:" 20 70 10 \
      "1" "Cai dat FileBrowser" \
      "2" "Start/Stop service" \
      "3" "Them user moi" \
      "4" "Doi mat khau" \
      "5" "Fix permissions" \
      "6" "Xem thong tin" \
      "7" "Quay lai" 3>&1 1>&2 2>&3)
  fi

  local num=$(echo "$choice" | grep -o '^[0-9]*')
  
  case "$num" in
    1) install_filemanager; read -p "Press Enter to continue..."; show_filemanager_menu ;;
    2) toggle_filemanager; read -p "Press Enter to continue..."; show_filemanager_menu ;;
    3) add_filemanager_user; read -p "Press Enter to continue..."; show_filemanager_menu ;;
    4) change_filemanager_password; read -p "Press Enter to continue..."; show_filemanager_menu ;;
    5) fix_filemanager_user; read -p "Press Enter to continue..."; show_filemanager_menu ;;
    6) show_filemanager_info; read -p "Press Enter to continue..."; show_filemanager_menu ;;
    7|"") show_main_menu ;;
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
  
  # Auto-detect and allow FileBrowser port
  if [ -n "${CONFIG_filemanager_port}" ]; then
    log_info "Opening FileBrowser port: ${CONFIG_filemanager_port}"
    ufw allow ${CONFIG_filemanager_port}/tcp
  elif [ -f "/etc/systemd/system/filebrowser.service" ]; then
    # Extract port from service file
    fb_port=$(grep -oP 'port \K[0-9]+' /etc/systemd/system/filebrowser.service 2>/dev/null || echo "8080")
    log_info "Opening FileBrowser port: ${fb_port}"
    ufw allow ${fb_port}/tcp
  fi
  
  # Auto-detect and allow phpMyAdmin port
  if [ -f "/etc/nginx/sites-available/phpmyadmin.conf" ]; then
    pma_port=$(grep -oP 'listen \K[0-9]+' /etc/nginx/sites-available/phpmyadmin.conf 2>/dev/null | head -1)
    if [ -n "$pma_port" ] && [ "$pma_port" != "80" ]; then
      log_info "Opening phpMyAdmin port: ${pma_port}"
      ufw allow ${pma_port}/tcp
    fi
  fi
  
  # Auto-detect NodeJS apps ports from PM2
  if command_exists pm2; then
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    # Get ports from PM2 apps (if PORT env var is set)
    pm2_ports=$(pm2 jlist 2>/dev/null | grep -oP '"PORT":\s*"\K[0-9]+' | sort -u)
    for port in $pm2_ports; do
      if [ -n "$port" ]; then
        log_info "Opening NodeJS app port: ${port}"
        ufw allow ${port}/tcp
      fi
    done
  fi
  
  echo ""
  ufw status numbered
  echo ""
  log_info "✅ Firewall configured!"
  log_info "💡 Các port đã mở: SSH(22), HTTP(80), HTTPS(443), FileBrowser, phpMyAdmin, NodeJS apps"
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
  source "$BASE_DIR/functions/setup_filemanager.sh"
  
  if command_exists filebrowser && [ -f "/etc/filebrowser/filebrowser.db" ]; then
    log_warn "FileBrowser đã được cài đặt"
    read -p "Bạn có muốn cài lại không? (y/n): " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || return 0
  fi
  
  install_filemanager
}

toggle_filemanager() {
  if service_is_active filebrowser; then
    systemctl stop filebrowser
    log_info "✅ FileBrowser stopped"
  else
    # Check if configured correctly
    if netstat -tlnp 2>/dev/null | grep -q "127.0.0.1:8080"; then
      log_warn "⚠️  FileBrowser đang listen trên 127.0.0.1 (localhost only)"
      log_info "Đang reconfigure để accessible từ internet..."
      source "$BASE_DIR/functions/setup_filemanager.sh"
      reconfigure_filemanager
    else
      systemctl start filebrowser
      log_info "✅ FileBrowser started"
    fi
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
    password=$(gum input --password --placeholder "New Password (min 12 chars)")
  else
    read -p "Username [admin]: " username
    username=${username:-admin}
    read -sp "New Password (min 12 chars): " password
    echo ""
  fi
  
  if [ -z "$password" ]; then
    log_error "Password cannot be empty"
    return 1
  fi
  
  if [ ${#password} -lt 12 ]; then
    log_error "Password must be at least 12 characters"
    return 1
  fi
  
  # Stop service to update database
  systemctl stop filebrowser
  sleep 2
  
  if filebrowser users update "$username" --password "$password" --database /etc/filebrowser/filebrowser.db 2>/dev/null; then
    log_info "✅ Password updated for $username"
    
    # Update log file
    sed -i "/filebrowser_pass=/d" "$BASE_DIR/logs/install.log" 2>/dev/null
    echo "filebrowser_pass=$password" >> "$BASE_DIR/logs/install.log"
    
    log_info "New credentials saved to log"
  else
    log_error "❌ Failed to update password"
  fi
  
  # Start service
  systemctl start filebrowser
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
    
    # Get credentials from log
    echo "👤 Login Credentials:"
    local fb_user=$(grep "filebrowser_user=" "$BASE_DIR/logs/install.log" 2>/dev/null | tail -1 | cut -d'=' -f2)
    local fb_pass=$(grep "filebrowser_pass=" "$BASE_DIR/logs/install.log" 2>/dev/null | tail -1 | cut -d'=' -f2)
    
    if [ -n "$fb_user" ] && [ -n "$fb_pass" ]; then
      echo "  Username: $fb_user"
      echo "  Password: $fb_pass"
      echo ""
      echo "  ℹ️  If password doesn't work, reset it via menu option 4"
    else
      echo "  Credentials not found in logs"
      echo "  Reset password via menu option 4"
    fi
    
    echo ""
    echo "📊 Statistics:"
    echo "  Database: /etc/filebrowser/filebrowser.db"
    if [ -f "/etc/filebrowser/filebrowser.db" ]; then
      local db_size=$(du -h /etc/filebrowser/filebrowser.db | awk '{print $1}')
      echo "  DB Size: $db_size"
    fi
  else
    echo "❌ FileBrowser is not running"
    echo ""
    echo "Start it via menu option 2"
  fi
  echo ""
}

# SSL functions (delegates to setup_ssl.sh)
install_ssl() {
  if $use_gum; then
    domain=$(gum input --placeholder "Nhập domain (vd: example.com)")
  else
    read -p "Nhập domain: " domain
  fi
  
  if [ -z "$domain" ]; then
    log_error "Domain không được để trống!"
    return 1
  fi
  
  log_info "🔐 Đang cài SSL cho domain: $domain"
  
  # Install certbot if not exists
  if ! command_exists certbot; then
    log_info "Cài đặt certbot..."
    apt-get update -qq
    apt-get install -y certbot python3-certbot-nginx
  fi
  
  # Find the config file for this domain
  local config_file=""
  local primary_domain=""
  
  # Check if domain has its own config
  if [ -f "/etc/nginx/sites-available/$domain.conf" ]; then
    config_file="/etc/nginx/sites-available/$domain.conf"
    primary_domain="$domain"
  else
    # Search for domain in all configs (might be an alias)
    for conf in /etc/nginx/sites-available/*.conf; do
      if [ -f "$conf" ] && grep -q "server_name.*$domain" "$conf"; then
        config_file="$conf"
        primary_domain=$(basename "$conf" .conf)
        log_info "📋 Tìm thấy domain trong config: $primary_domain"
        break
      fi
    done
  fi
  
  if [ -z "$config_file" ]; then
    log_error "❌ Không tìm thấy Nginx config cho domain: $domain"
    log_error "   Vui lòng tạo website trước khi cài SSL"
    return 1
  fi
  
  # Get all domains from server_name directive
  local all_domains=$(grep "server_name" "$config_file" | head -1 | sed 's/server_name//' | tr -d ';' | xargs)
  
  log_info "📋 Domains trong config:"
  for d in $all_domains; do
    log_info "   - $d"
  done
  
  # Build certbot command with all domains
  local certbot_domains=""
  for d in $all_domains; do
    certbot_domains="$certbot_domains -d $d"
  done
  
  # Request SSL certificate only (certonly mode)
  log_info "🔐 Request SSL certificate từ Let's Encrypt..."
  
  # Check if certificate already exists for first domain
  local cert_domain=$(echo $all_domains | awk '{print $1}')
  local expand_flag=""
  if [ -d "/etc/letsencrypt/live/$cert_domain" ]; then
    log_info "ℹ️  Tìm thấy certificate cũ, sẽ expand để thêm domains mới"
    expand_flag="--expand"
  fi
  
  if certbot certonly --nginx $certbot_domains $expand_flag --non-interactive --agree-tos --email "admin@$primary_domain"; then
    log_info "✅ Certificate issued thành công!"
    
    # Manually configure SSL in Nginx
    log_info "🔧 Đang cấu hình SSL trong Nginx..."
    
    # Backup config
    cp "$config_file" "${config_file}.bak"
    
    # Get first domain for cert path
    local cert_domain=$(echo $all_domains | awk '{print $1}')
    
    # Update config to add SSL
    # Check if SSL already configured
    if ! grep -q "listen 443 ssl" "$config_file"; then
      # Add SSL server block
      sed -i "/listen 80;/a\    listen 443 ssl http2;\n    ssl_certificate /etc/letsencrypt/live/$cert_domain/fullchain.pem;\n    ssl_certificate_key /etc/letsencrypt/live/$cert_domain/privkey.pem;\n    ssl_protocols TLSv1.2 TLSv1.3;\n    ssl_ciphers HIGH:!aNULL:!MD5;" "$config_file"
      
      # Add HTTP to HTTPS redirect
      cat >> "$config_file" <<EOF

# HTTP to HTTPS redirect
server {
    listen 80;
    server_name $all_domains;
    return 301 https://\$host\$request_uri;
}
EOF
    else
      log_info "ℹ️  SSL đã được cấu hình trước đó, chỉ cập nhật certificate"
    fi
    
    # Test nginx config
    if nginx -t 2>/dev/null; then
      systemctl reload nginx
      rm -f "${config_file}.bak"
      
      echo ""
      log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      log_info "✅ SSL ĐÃ ĐƯỢC CÀI ĐẶT THÀNH CÔNG!"
      log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      log_info "🔒 HTTPS URLs:"
      for d in $all_domains; do
        log_info "   - https://$d"
      done
      log_info "📜 Certificate: /etc/letsencrypt/live/$cert_domain/"
      log_info "📅 Expires: $(date -d "+90 days" +%Y-%m-%d)"
      log_info "🔄 Auto-renew: Enabled"
      log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    else
      log_error "❌ Nginx config có lỗi, rollback..."
      mv "${config_file}.bak" "$config_file"
      systemctl reload nginx
      return 1
    fi
  else
    log_error "❌ Không thể issue certificate. Kiểm tra:"
    log_error "  1. Domain đã trỏ đúng IP chưa? (DNS A record)"
    log_error "  2. Port 80 có accessible từ internet không? (Firewall)"
    log_error "  3. Nginx đang chạy và serving domain không?"
    echo ""
    log_info "💡 Test DNS: dig +short $domain"
    log_info "💡 Test HTTP: curl -I http://$domain"
    return 1
  fi
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

# phpMyAdmin installation wrapper
install_phpmyadmin_menu() {
  source "$BASE_DIR/functions/setup_phpmyadmin.sh"
  
  if [ -d "/var/www/phpmyadmin" ]; then
    log_warn "⚠️  phpMyAdmin đã được cài đặt"
    read -p "Bạn có muốn cài lại không? (y/n): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
      return 0
    fi
    uninstall_phpmyadmin
  fi
  
  if $use_gum; then
    mode=$(gum choose "Port-based (8081)" "Subdomain (pma.domain.com)")
  else
    echo "Choose installation mode:"
    echo "1) Port-based (http://IP:8081)"
    echo "2) Subdomain (http://pma.domain.com)"
    read -p "Select [1]: " mode_choice
    mode_choice=${mode_choice:-1}
    if [ "$mode_choice" = "2" ]; then
      mode="Subdomain"
    else
      mode="Port-based"
    fi
  fi
  
  if [[ "$mode" == *"Subdomain"* ]]; then
    export CONFIG_phpmyadmin_mode="subdomain"
    if $use_gum; then
      domain=$(gum input --placeholder "Enter subdomain (e.g., pma.example.com)")
    else
      read -p "Enter subdomain: " domain
    fi
    export CONFIG_phpmyadmin_domain="$domain"
  else
    export CONFIG_phpmyadmin_mode="port"
    export CONFIG_phpmyadmin_port="8081"
  fi
  
  install_phpmyadmin
}

# Show phpMyAdmin info wrapper
show_phpmyadmin_info() {
  source "$BASE_DIR/functions/setup_phpmyadmin.sh"
  show_phpmyadmin_info
}

# List MySQL users wrapper
list_mysql_users() {
  source "$BASE_DIR/functions/setup_phpmyadmin.sh"
  list_mysql_users
}

# Change MySQL password wrapper
change_mysql_password() {
  source "$BASE_DIR/functions/setup_phpmyadmin.sh"
  change_mysql_password
}

# Reset MySQL root password wrapper
reset_mysql_root_password() {
  source "$BASE_DIR/functions/setup_phpmyadmin.sh"
  reset_mysql_root_password
}

# Restart MySQL service wrapper
restart_mysql_service() {
  source "$BASE_DIR/functions/setup_phpmyadmin.sh"
  restart_mysql_service
}

# ------------------------------------------------------
# URL Password Protection Functions
# ------------------------------------------------------

# Protect URL with password
protect_url_with_password() {
  clear
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🔒 BẢO MẬT URL BẰNG PASSWORD"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  # Ask for URL type
  echo "Chọn loại URL cần bảo vệ:"
  if $use_gum; then
    url_type=$(gum choose "1. Domain-based (ví dụ: vinainbox.com/admin)" "2. Custom URL với IP:Port (ví dụ: 34.81.56.243:8080/)")
  else
    echo "1. Domain-based (ví dụ: vinainbox.com/admin)"
    echo "2. Custom URL với IP:Port (ví dụ: 34.81.56.243:8080/)"
    read -p "Chọn [1/2]: " url_choice
    url_type="1. Domain-based"
    [ "$url_choice" = "2" ] && url_type="2. Custom URL với IP:Port"
  fi
  
  if [[ "$url_type" == *"Custom"* ]]; then
    # Custom URL mode
    if $use_gum; then
      custom_url=$(gum input --placeholder "Nhập custom URL (ví dụ: http://34.81.56.243:8080/ hoặc 34.81.56.243:8080/)")
    else
      read -p "Nhập custom URL (ví dụ: http://34.81.56.243:8080/): " custom_url
    fi
    
    if [ -z "$custom_url" ]; then
      log_error "URL không được để trống!"
      return 1
    fi
    
    # Extract IP:port and path
    if [[ "$custom_url" =~ ^https?:// ]]; then
      custom_url=${custom_url#http://}
      custom_url=${custom_url#https://}
    fi
    
    # Split into IP:port and path
    IFS='/' read -r ip_port path_part <<< "$custom_url"
    
    # Find nginx config that matches this IP:port
    config_file=""
    # Check all nginx configs for matching listen directive
    for conf in /etc/nginx/sites-available/*.conf; do
      if [ -f "$conf" ]; then
        # Check if config has matching listen directive
        if grep -q "listen.*$ip_port" "$conf"; then
          config_file="$conf"
          break
        fi
      fi
    done
    
    # Also check sites-enabled
    if [ -z "$config_file" ]; then
      for conf in /etc/nginx/sites-enabled/*.conf; do
        if [ -f "$conf" ]; then
          if grep -q "listen.*$ip_port" "$conf"; then
            config_file="$conf"
            break
          fi
        fi
      done
    fi
    
    # If no exact match, try to find by port only
    if [ -z "$config_file" ]; then
      port=$(echo "$ip_port" | grep -oP ':\K[0-9]+')
      if [ -n "$port" ]; then
        for conf in /etc/nginx/sites-available/*.conf; do
          if [ -f "$conf" ] && grep -q "listen.*$port" "$conf"; then
            config_file="$conf"
            log_warn "⚠️  Không tìm thấy exact match, sử dụng config có port $port"
            break
          fi
        done
      fi
    fi
    
    if [ -z "$config_file" ]; then
      log_error "❌ Không tìm thấy nginx config cho URL: $custom_url"
      log_info "💡 Kiểm tra lại URL hoặc IP:Port"
      return 1
    fi
    
    # Use root path if no path specified
    path=${path_part:-/}
    
  else
    # Domain-based mode
    # Get domain
    if $use_gum; then
      domain=$(gum input --placeholder "Nhập domain (ví dụ: vinainbox.com)")
    else
      read -p "Nhập domain (ví dụ: vinainbox.com): " domain
    fi
    
    if [ -z "$domain" ]; then
      log_error "Domain không được để trống!"
      return 1
    fi
    
    # Check if domain config exists
    if [ ! -f "/etc/nginx/sites-available/${domain}.conf" ]; then
      log_error "❌ Không tìm thấy config cho domain: $domain"
      log_info "💡 Hãy tạo website trước với menu option 1"
      return 1
    fi
    
    config_file="/etc/nginx/sites-available/${domain}.conf"
    
    # Get path to protect
    if $use_gum; then
      path=$(gum input --placeholder "Nhập path cần bảo vệ (ví dụ: /admin)" --value "/admin")
    else
      read -p "Nhập path cần bảo vệ (ví dụ: /admin) [/admin]: " path
      path=${path:-/admin}
    fi
    
    # Use domain as identifier
    ip_port="$domain"
  fi
  
  # Ensure path starts with /
  if [[ ! "$path" =~ ^/ ]]; then
    path="/$path"
  fi
  
  # Get location identifier for filename
  location_id=$(echo "${ip_port}${path}" | tr '/:' '_' | sed 's/__*/_/g')
  
  # Get username
  if $use_gum; then
    username=$(gum input --placeholder "Username để đăng nhập")
  else
    read -p "Username để đăng nhập: " username
  fi
  
  if [ -z "$username" ]; then
    log_error "Username không được để trống!"
    return 1
  fi
  
  # Get password
  if $use_gum; then
    password=$(gum input --password --placeholder "Password")
  else
    read -sp "Password: " password
    echo ""
  fi
  
  if [ -z "$password" ]; then
    log_error "Password không được để trống!"
    return 1
  fi
  
  # Install apache2-utils if not exists
  if ! command_exists htpasswd; then
    log_info "📦 Đang cài đặt apache2-utils..."
    apt-get update -qq
    apt-get install -y apache2-utils
  fi
  
  # Create htpasswd directory if not exists
  htpasswd_dir="/etc/nginx/htpasswd"
  mkdir -p "$htpasswd_dir"
  
  # Create or update .htpasswd file with location_id
  htpasswd_file="$htpasswd_dir/${location_id}.htpasswd"
  
  log_info "🔐 Đang tạo password file..."
  
  # Check if file exists to determine if we need -c flag
  if [ -f "$htpasswd_file" ]; then
    log_warn "⚠️  File password đã tồn tại, đang cập nhật password cho user: $username"
    # File exists, just update/add user
    htpasswd -b "$htpasswd_file" "$username" "$password"
  else
    log_info "📝 Tạo file password mới: $htpasswd_file"
    # File doesn't exist, create it with -c flag
    htpasswd -bc "$htpasswd_file" "$username" "$password"
  fi
  
  if [ ! $? -eq 0 ]; then
    log_error "❌ Không thể tạo/cập nhật password file"
    return 1
  fi
  
  log_info "✅ Password file đã được tạo/cập nhật thành công"
  
  # Set permissions for htpasswd file so nginx can read it
  chmod 644 "$htpasswd_file"
  chown www-data:www-data "$htpasswd_file" 2>/dev/null || chmod 644 "$htpasswd_file"
  log_info "📝 Đã set permissions cho password file"
  
  # Backup Nginx config
  cp "$config_file" "${config_file}.bak"
  
  log_info "🔧 Đang cập nhật Nginx config..."
  
  # Check if location block with auth already exists for this path
  if grep -A5 "location.*$path" "$config_file" | grep -q "auth_basic"; then
    log_warn "⚠️  URL này đã được bảo vệ (có auth_basic), đang xóa location block cũ để thêm lại..."
    
    # Remove ALL location blocks that match this path
    awk -v path="$path" '
    BEGIN { skip_block=0; depth=0 }
    {
      # Detect location block start that matches our path
      if (/location[[:space:]]+.*\{/ && $0 ~ path) {
        skip_block=1
        depth=1
        next
      }
      
      # Track braces in location block
      if (skip_block) {
        if (/{/) depth++
        if (/}/) {
          depth--
          if (depth <= 0) {
            skip_block=0
            depth=0
          }
        }
        next
      }
      
      print
    }
    ' "$config_file" > "${config_file}.tmp"
    
    # Verify removal
    if grep -q "location.*$path" "${config_file}.tmp"; then
      log_warn "⚠️  Vẫn còn location block cho path này, có thể có nhiều blocks"
    else
      log_info "✅ Đã xóa location block cũ"
    fi
    
    mv "${config_file}.tmp" "$config_file"
  elif grep -q "location.*$path" "$config_file"; then
    # Location exists but without auth_basic - replace it
    log_warn "⚠️  Location block đã tồn tại nhưng chưa có auth, đang xóa và thêm lại..."
    
    awk -v path="$path" '
    BEGIN { skip_block=0; depth=0 }
    {
      if (/location[[:space:]]+.*\{/ && $0 ~ path) {
        skip_block=1
        depth=1
        next
      }
      
      if (skip_block) {
        if (/{/) depth++
        if (/}/) {
          depth--
          if (depth <= 0) {
            skip_block=0
            depth=0
          }
        }
        next
      }
      
      print
    }
    ' "$config_file" > "${config_file}.tmp"
    mv "${config_file}.tmp" "$config_file"
  fi
  
  # Add new location block with password protection
  # SIMPLE APPROACH: Add before the LAST closing brace in the file
  
  # Get all lines with "}" and get the last one that's on its own line
  closing_braces=$(grep -n "^}" "$config_file" | cut -d: -f1)
  
  if [ -z "$closing_braces" ]; then
    log_error "❌ Không tìm thấy closing brace trong config"
    return 1
  fi
  
  # Get the last closing brace (from last line of the ones found)
  target_line=$(echo "$closing_braces" | tail -1)
  
  log_info "📝 Vị trí đóng server block cuối cùng tại dòng: $target_line"
  
  # Insert location block before the closing brace
  head -n $((target_line - 1)) "$config_file" > "${config_file}.tmp"
  
  cat >> "${config_file}.tmp" <<EOF
    # Password protected location: $path
    location $path {
        auth_basic "Restricted Area";
        auth_basic_user_file $htpasswd_file;
        
        # Allow existing content to work
        index index.html index.php;
        try_files \$uri \$uri/ =404;
    }
}
EOF
  
  # Add the rest of file after the closing brace (in case there are more server blocks after)
  if [ $target_line -lt $(wc -l < "$config_file") ]; then
    tail -n +$((target_line + 1)) "$config_file" >> "${config_file}.tmp"
  fi
  
  mv "${config_file}.tmp" "$config_file"
  log_info "✅ Đã thêm location block vào trong server block"
  
  # Debug: Show what was added
  log_info "📋 Đã thêm location block bảo vệ path: $path"
  log_info "📋 Config file: $config_file"
  log_info "📋 Htpasswd file: $htpasswd_file"
  
  # Show the added location block for verification
  log_info ""
  log_info "📝 Location block đã được thêm cho path: $path"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  location_content=$(grep -A20 "location.*$path" "$config_file" 2>/dev/null | head -25)
  if [ -n "$location_content" ]; then
    echo "$location_content"
    echo ""
    log_info "✅ Location block đã được thêm vào nginx config"
    
    # Verify it has auth_basic
    if echo "$location_content" | grep -q "auth_basic"; then
      log_info "✅ Có auth_basic directive - URL sẽ yêu cầu password"
    else
      log_error "❌ KHÔNG TÌM THẤY auth_basic trong location block!"
      log_warn "Location block có thể chưa được thêm đúng"
    fi
  else
    log_warn "⚠️  Không thấy location block trong config"
    log_warn "📁 Kiểm tra file: $config_file"
  fi
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  log_info ""
  
  # Test Nginx config
  log_info "🔍 Đang kiểm tra nginx config..."
  nginx_test_output=$(nginx -t 2>&1)
  nginx_test_status=$?
  
  if [ $nginx_test_status -eq 0 ]; then
    log_info "✅ Nginx config hợp lệ"
    systemctl reload nginx
    log_info "🔄 Đã reload nginx"
    rm -f "${config_file}.bak"
    
    echo ""
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "✅ BẢO MẬT URL THÀNH CÔNG!"
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "🔒 Protected URL: ${ip_port}${path}"
    log_info "👤 Username: $username"
    log_info "📁 Password file: $htpasswd_file"
    log_info "📝 Config file: $config_file"
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "💡 Giờ khi truy cập URL sẽ yêu cầu nhập password"
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  else
    log_error "❌ Nginx config có lỗi!"
    echo "$nginx_test_output"
    log_error "Rollback config..."
    mv "${config_file}.bak" "$config_file"
    systemctl reload nginx
    rm -f "$htpasswd_file"
    return 1
  fi
}

# Remove URL password protection
remove_url_password() {
  clear
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🗑️  XÓA BẢO MẬT URL"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  # Ask for URL type
  echo "Chọn loại URL cần xóa bảo vệ:"
  if $use_gum; then
    url_type=$(gum choose "1. Domain-based (ví dụ: vinainbox.com/admin)" "2. Custom URL với IP:Port (ví dụ: 34.81.56.243:8080/)")
  else
    echo "1. Domain-based (ví dụ: vinainbox.com/admin)"
    echo "2. Custom URL với IP:Port (ví dụ: 34.81.56.243:8080/)"
    read -p "Chọn [1/2]: " url_choice
    url_type="1. Domain-based"
    [ "$url_choice" = "2" ] && url_type="2. Custom URL với IP:Port"
  fi
  
  if [[ "$url_type" == *"Custom"* ]]; then
    # Custom URL mode
    if $use_gum; then
      custom_url=$(gum input --placeholder "Nhập custom URL (ví dụ: http://34.81.56.243:8080/ hoặc 34.81.56.243:8080/)")
    else
      read -p "Nhập custom URL (ví dụ: http://34.81.56.243:8080/): " custom_url
    fi
    
    if [ -z "$custom_url" ]; then
      log_error "URL không được để trống!"
      return 1
    fi
    
    # Extract IP:port and path
    if [[ "$custom_url" =~ ^https?:// ]]; then
      custom_url=${custom_url#http://}
      custom_url=${custom_url#https://}
    fi
    
    # Split into IP:port and path
    IFS='/' read -r ip_port path_part <<< "$custom_url"
    
    # Use root path if no path specified
    path=${path_part:-/}
    
    # Find nginx config that matches this IP:port
    config_file=""
    port=$(echo "$ip_port" | grep -oP ':\K[0-9]+')
    if [ -n "$port" ]; then
      for conf in /etc/nginx/sites-available/*.conf; do
        if [ -f "$conf" ] && grep -q "listen.*$port" "$conf"; then
          config_file="$conf"
          break
        fi
      done
    fi
    
    if [ -z "$config_file" ]; then
      log_error "❌ Không tìm thấy nginx config cho URL"
      return 1
    fi
    
  else
    # Domain-based mode
    # Get domain
    if $use_gum; then
      domain=$(gum input --placeholder "Nhập domain")
    else
      read -p "Nhập domain: " domain
    fi
    
    if [ -z "$domain" ]; then
      log_error "Domain không được để trống!"
      return 1
    fi
    
    # Check if domain config exists
    if [ ! -f "/etc/nginx/sites-available/${domain}.conf" ]; then
      log_error "❌ Không tìm thấy config cho domain: $domain"
      return 1
    fi
    
    config_file="/etc/nginx/sites-available/${domain}.conf"
    
    # Get path
    if $use_gum; then
      path=$(gum input --placeholder "Nhập path cần xóa bảo vệ (ví dụ: /admin)")
    else
      read -p "Nhập path cần xóa bảo vệ (ví dụ: /admin): " path
    fi
    
    if [ -z "$path" ]; then
      log_error "Path không được để trống!"
      return 1
    fi
    
    ip_port="$domain"
  fi
  
  # Ensure path starts with /
  if [[ ! "$path" =~ ^/ ]]; then
    path="/$path"
  fi
  
  # Create location_id for htpasswd filename
  location_id=$(echo "${ip_port}${path}" | tr '/:' '_' | sed 's/__*/_/g')
  
  # Check if protection exists
  if ! grep -q "location.*$path" "$config_file"; then
    log_warn "⚠️  Không tìm thấy bảo vệ cho ${ip_port}${path}"
    return 1
  fi
  
  # Backup config
  cp "$config_file" "${config_file}.bak"
  
  log_info "🗑️  Đang xóa password protection..."
  
  # Remove the location block with auth
  # This is a simplified approach - remove the entire location block
  awk -v path="$path" '
  BEGIN { in_location=0; skip_block=0 }
  {
    # Detect location block start
    if (/location.*\{/ && $0 ~ path) {
      in_location=1
      skip_block=1
      next
    }
    
    # Skip everything in the block
    if (skip_block) {
      # Track braces
      if (/\{/) {
        depth++
      }
      if (/\}/) {
        depth--
        if (depth <= 0) {
          in_location=0
          skip_block=0
          depth=0
        }
      }
      next
    }
    
    print
  }
  ' "$config_file" > "${config_file}.tmp"
  
  mv "${config_file}.tmp" "$config_file"
  
  # Test Nginx config
  if nginx -t &>/dev/null; then
    systemctl reload nginx
    rm -f "${config_file}.bak"
    
    # Also remove htpasswd file if exists
    htpasswd_file="/etc/nginx/htpasswd/${location_id}.htpasswd"
    if [ -f "$htpasswd_file" ]; then
      rm -f "$htpasswd_file"
      log_info "🗑️  Đã xóa password file: $htpasswd_file"
    fi
    
    echo ""
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "✅ ĐÃ XÓA BẢO MẬT THÀNH CÔNG!"
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "🔓 URL đã mở: ${ip_port}${path}"
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  else
    log_error "❌ Nginx config có lỗi, rollback..."
    mv "${config_file}.bak" "$config_file"
    systemctl reload nginx
    return 1
  fi
}

# ------------------------------------------------------
# Chay menu chinh - only if called directly
# ------------------------------------------------------
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  while true; do
    show_main_menu
  done
fi
