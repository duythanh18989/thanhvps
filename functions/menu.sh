#!/bin/bash
# ======================================================
# 🧭 MENU QUẢN LÝ VPS (Giao diện GUM / WHIPTAIL)
# ------------------------------------------------------
# Tác giả: ThanhTV | Phiên bản: 1.5
# Script hỗ trợ menu quản lý Website, Database,
# Backup, Hệ thống, Auto Update.
# ======================================================

BASE_DIR="$(dirname "$(realpath "$0")")"
LOG_FILE="/var/log/menu_vps.log"

# ------------------------------------------------------
# Tự động load tất cả function/module nếu có
# ------------------------------------------------------
for file in "$BASE_DIR"/functions/*.sh; do
  [ -f "$file" ] && source "$file"
done

# ------------------------------------------------------
# Kiểm tra GUM (UI đẹp) hay fallback WHIPTAIL
# ------------------------------------------------------
use_gum=false
if command -v gum &>/dev/null; then
  use_gum=true
fi

# ------------------------------------------------------
# Menu chính
# ------------------------------------------------------
show_main_menu() {
  if $use_gum; then
    clear
    echo "🌐  QUẢN LÝ VPS - Chọn chức năng bạn cần:"
    choice=$(gum choose \
      "1️⃣  Quản lý Website" \
      "2️⃣  Quản lý Database" \
      "3️⃣  Backup & Phục hồi" \
      "4️⃣  Quản trị Hệ thống" \
      "5️⃣  Auto Update Script" \
      "6️⃣  Thoát")
  else
    choice=$(whiptail --title "Menu Quản Lý VPS" --menu "Chọn chức năng:" 20 70 10 \
      "1" "Quản lý Website" \
      "2" "Quản lý Database" \
      "3" "Backup & Phục hồi" \
      "4" "Quản trị Hệ thống" \
      "5" "Auto Update Script" \
      "6" "Thoát" 3>&1 1>&2 2>&3)
  fi

  case "$choice" in
    Website|1) show_website_menu ;;
    Database|2) show_db_menu ;;
    Backup|3) bash "$BASE_DIR/functions/backup.sh" ;;
    Hệ thống|4) bash "$BASE_DIR/functions/system.sh" ;;
    Update|5) bash "$BASE_DIR/functions/autoupdate.sh" ;;
    Thoát|6) echo "👋 Tạm biệt!"; exit 0 ;;
  esac
}

# ------------------------------------------------------
# Menu con: Quản lý Website
# ------------------------------------------------------
show_website_menu() {
  if $use_gum; then
    choice=$(gum choose \
      "➕  Thêm website mới" \
      "❌  Xóa website" \
      "🧾  Danh sách website" \
      "🔍  Xem log website" \
      "🔄  Restart Nginx/PHP" \
      "⬅️  Quay lại")
  else
    choice=$(whiptail --title "Quản lý Website" --menu "Chọn tác vụ:" 20 70 10 \
      "1" "Thêm website mới" \
      "2" "Xóa website" \
      "3" "Danh sách website" \
      "4" "Xem log website" \
      "5" "Restart Nginx/PHP" \
      "6" "Quay lại" 3>&1 1>&2 2>&3)
  fi

  case "$choice" in
    Thêm|1) add_website ;;
    Xóa|2) remove_website ;;
    Danh sách|3) list_websites ;;
    log|4) view_logs ;;
    Restart|5) restart_nginx_php ;;
    Quay lại|6) show_main_menu ;;
  esac
}

# ------------------------------------------------------
# Menu con: Database
# ------------------------------------------------------
show_db_menu() {
  if $use_gum; then
    choice=$(gum choose \
      "🧩  Tạo database mới" \
      "❌  Xóa database" \
      "📋  Danh sách database" \
      "⬅️  Quay lại")
  else
    choice=$(whiptail --title "Quản lý Database" --menu "Chọn tác vụ:" 20 70 10 \
      "1" "Tạo database mới" \
      "2" "Xóa database" \
      "3" "Danh sách database" \
      "4" "Quay lại" 3>&1 1>&2 2>&3)
  fi

  case "$choice" in
    Tạo|1) create_db ;;
    Xóa|2) delete_db ;;
    Danh sách|3) list_db ;;
    Quay lại|4) show_main_menu ;;
  esac
}

# ------------------------------------------------------
# Chạy menu chính
# ------------------------------------------------------
while true; do
  show_main_menu
done
