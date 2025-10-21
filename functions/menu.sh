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
# Load all other function modules (exclude autoupdate.sh)
# ------------------------------------------------------
for file in "$BASE_DIR"/functions/*.sh; do
  [ -f "$file" ] && \
  [ "$file" != "$BASE_DIR/functions/utils.sh" ] && \
  [ "$file" != "$BASE_DIR/functions/autoupdate.sh" ] && \
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
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🚀 ThanhTV VPS - MENU QUẢN LÝ"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    choice=$(gum choose \
      "1  Quan ly Website" \
      "2  Quan ly Database" \
      "3  Backup & Phuc hoi" \
      "4  Quan tri He thong" \
      "5  Auto Update Script" \
      "6  Thoat")
  else
    choice=$(whiptail --title "Menu Quan Ly VPS" --menu "Chon chuc nang:" 20 70 10 \
      "1" "Quan ly Website" \
      "2" "Quan ly Database" \
      "3" "Backup & Phuc hoi" \
      "4" "Quan tri He thong" \
      "5" "Auto Update Script" \
      "6" "Thoat" 3>&1 1>&2 2>&3)
  fi

  # Parse choice (extract number)
  local num=$(echo "$choice" | grep -o '^[0-9]*')
  
  case "$num" in
    1) show_website_menu ;;
    2) show_db_menu ;;
    3) show_backup_menu ;;
    4) show_system_menu ;;
    5) bash "$BASE_DIR/functions/autoupdate.sh"; read -p "Press Enter to continue..."; show_main_menu ;;
    6|"") echo "Tam biet!"; exit 0 ;;
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
  if command_exists show_system_menu_internal; then
    show_system_menu_internal
    show_main_menu
  else
    clear
    bash "$BASE_DIR/functions/system.sh"
    read -p "Press Enter to continue..."
    show_main_menu
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
