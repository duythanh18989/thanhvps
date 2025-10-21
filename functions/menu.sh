#!/bin/bash
# ======================================================
# MENU QUAN LY VPS (Giao dien GUM / WHIPTAIL)
# ------------------------------------------------------
# Tac gia: ThanhTV | Phien ban: 1.5
# Script ho tro menu quan ly Website, Database,
# Backup, He thong, Auto Update.
# ======================================================

BASE_DIR="$(dirname "$(realpath "$0")")"
LOG_FILE="/var/log/menu_vps.log"

# ------------------------------------------------------
# Tu dong load tat ca function/module neu co
# ------------------------------------------------------
for file in "$BASE_DIR"/functions/*.sh; do
  [ -f "$file" ] && source "$file"
done

# ------------------------------------------------------
# Kiem tra GUM (UI dep) hay fallback WHIPTAIL
# ------------------------------------------------------
use_gum=false
if command -v gum &>/dev/null; then
  use_gum=true
fi

# ------------------------------------------------------
# Menu chinh
# ------------------------------------------------------
show_main_menu() {
  if $use_gum; then
    clear
    echo "QUAN LY VPS - Chon chuc nang:"
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

  case "$choice" in
    1) show_website_menu ;;
    2) show_db_menu ;;
    3) bash "$BASE_DIR/functions/backup.sh" ;;
    4) bash "$BASE_DIR/functions/system.sh" ;;
    5) bash "$BASE_DIR/functions/autoupdate.sh" ;;
    6) echo "Tam biet!"; exit 0 ;;
  esac
}

# ------------------------------------------------------
# Menu con: Quan ly Website
# ------------------------------------------------------
show_website_menu() {
  if $use_gum; then
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

  case "$choice" in
    1) add_website ;;
    2) remove_website ;;
    3) list_websites ;;
    4) view_logs ;;
    5) restart_nginx_php ;;
    6) show_main_menu ;;
  esac
}

# ------------------------------------------------------
# Menu con: Database
# ------------------------------------------------------
show_db_menu() {
  if $use_gum; then
    choice=$(gum choose \
      "1  Tao database moi" \
      "2  Xoa database" \
      "3  Danh sach database" \
      "4  Quay lai")
  else
    choice=$(whiptail --title "Quan ly Database" --menu "Chon tac vu:" 20 70 10 \
      "1" "Tao database moi" \
      "2" "Xoa database" \
      "3" "Danh sach database" \
      "4" "Quay lai" 3>&1 1>&2 2>&3)
  fi

  case "$choice" in
    1) create_db ;;
    2) delete_db ;;
    3) list_db ;;
    4) show_main_menu ;;
  esac
}

# ------------------------------------------------------
# Chay menu chinh
# ------------------------------------------------------
while true; do
  show_main_menu
done
