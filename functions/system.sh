#!/bin/bash
# ============================================================
# ⚙️ MODULE: CÔNG CỤ QUẢN TRỊ HỆ THỐNG VPS
# ------------------------------------------------------------
# Tác giả: ThanhTV
# Version: v1.0
# Mô tả:
#   - Quản lý service
#   - Dọn dẹp hệ thống
#   - Cập nhật package
#   - Xem thông tin VPS
# ============================================================

LOG_FILE="/var/log/system_tools.log"

# ------------------------------------------------------------
# 🧠 HÀM: Hiển thị thông tin hệ thống
# ------------------------------------------------------------
show_sysinfo() {
  echo "============================================="
  echo "🧠 THÔNG TIN HỆ THỐNG VPS"
  echo "============================================="
  echo "🖥️  OS: $(lsb_release -d | cut -f2)"
  echo "🧩 Kernel: $(uname -r)"
  echo "🧮 CPU: $(lscpu | grep 'Model name' | cut -d: -f2)"
  echo "💾 RAM: $(free -h | awk '/Mem:/ {print $2}')"
  echo "📦 Disk: $(df -h / | awk 'NR==2 {print $2}')"
  echo "⏱️  Uptime: $(uptime -p)"
  echo "🌐 IP: $(hostname -I | awk '{print $1}')"
  echo "============================================="
}

# ------------------------------------------------------------
# 🔧 HÀM: Restart service
# ------------------------------------------------------------
restart_services() {
  echo "🔄 Restart dịch vụ web..."
  systemctl restart nginx
  for v in 7.4 8.1 8.2 8.3; do
    systemctl restart php${v}-fpm 2>/dev/null
  done
  systemctl restart mariadb 2>/dev/null || systemctl restart mysql 2>/dev/null
  systemctl restart filebrowser 2>/dev/null
  echo "✅ Toàn bộ dịch vụ đã restart xong."
  echo "$(date '+%Y-%m-%d %H:%M:%S') | RESTART SERVICES" >> "$LOG_FILE"
}

# ------------------------------------------------------------
# 🧹 HÀM: Dọn dẹp hệ thống
# ------------------------------------------------------------
clean_system() {
  echo "🧹 Đang dọn dẹp hệ thống..."
  apt-get autoremove -y >/dev/null 2>&1
  apt-get autoclean -y >/dev/null 2>&1
  rm -rf /var/log/*.log /var/log/nginx/*.log /tmp/* >/dev/null 2>&1
  echo "✅ Dọn dẹp hoàn tất."
  echo "$(date '+%Y-%m-%d %H:%M:%S') | CLEAN SYSTEM" >> "$LOG_FILE"
}

# ------------------------------------------------------------
# 📦 HÀM: Cập nhật hệ thống
# ------------------------------------------------------------
update_system() {
  echo "📦 Cập nhật hệ thống (apt update & upgrade)..."
  apt-get update -y && apt-get upgrade -y
  echo "✅ Hệ thống đã cập nhật xong."
  echo "$(date '+%Y-%m-%d %H:%M:%S') | UPDATE SYSTEM" >> "$LOG_FILE"
}

# ------------------------------------------------------------
# 💾 HÀM: Kiểm tra dung lượng ổ đĩa
# ------------------------------------------------------------
check_disk() {
  echo "============================================="
  echo "💾 DUNG LƯỢNG Ổ ĐĨA"
  echo "============================================="
  df -h | grep -E "^Filesystem|/dev/"
  echo "---------------------------------------------"
  echo "📁 Dung lượng từng site:"
  du -sh /var/www/* 2>/dev/null || echo "Không có site nào."
  echo "============================================="
}

# ------------------------------------------------------------
# 🧰 MENU QUẢN LÝ HỆ THỐNG
# ------------------------------------------------------------
show_system_menu_internal() {
  while true; do
    clear
    echo "============================================="
    echo "⚙️  CÔNG CỤ QUẢN TRỊ HỆ THỐNG VPS"
    echo "============================================="
    echo "1️⃣  Xem thông tin hệ thống"
    echo "2️⃣  Restart dịch vụ web"
    echo "3️⃣  Dọn dẹp hệ thống"
    echo "4️⃣  Cập nhật hệ thống"
    echo "5️⃣  Kiểm tra dung lượng ổ đĩa"
    echo "6️⃣  Quay lại menu chính"
    echo "---------------------------------------------"
    read -p "👉 Chọn thao tác: " opt

    case $opt in
      1) show_sysinfo; read -p "Press Enter to continue..." ;;
      2) restart_services; read -p "Press Enter to continue..." ;;
      3) clean_system; read -p "Press Enter to continue..." ;;
      4) update_system; read -p "Press Enter to continue..." ;;
      5) check_disk; read -p "Press Enter to continue..." ;;
      6) return 0 ;;
      *) echo "❌ Lựa chọn không hợp lệ."; sleep 1 ;;
    esac
  done
}

# Alias for compatibility
show_system_menu() {
  show_system_menu_internal
}

# Nếu gọi trực tiếp file (không phải từ menu.sh)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  show_system_menu_internal
fi
