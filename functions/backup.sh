#!/bin/bash
# ============================================================
# 💾 MODULE: BACKUP TOÀN BỘ WEBSITE & DATABASE
# ------------------------------------------------------------
# Tác giả: ThanhTV
# Version: v1.0
# Mô tả:
#   - Backup toàn bộ file website + dump DB
#   - Cho phép chọn domain cụ thể
#   - Tạo cron backup tự động mỗi ngày
#   - Giữ lại X ngày gần nhất
# ============================================================

BASE_DIR=$(dirname "$(realpath "$0")")/../..
LOG_FILE="/var/log/backup_vps.log"
BACKUP_ROOT="/opt/backups/sites"
DB_BACKUP_DIR="/opt/backups/mysql"
KEEP_DAYS=7
CRON_SCHEDULE="30 2 * * *" # 02:30 AM hằng ngày

# ------------------------------------------------------------
# 🧩 HÀM: Tạo thư mục backup
# ------------------------------------------------------------
init_backup_dir() {
  mkdir -p "$BACKUP_ROOT"
  mkdir -p "$DB_BACKUP_DIR"
  chmod -R 700 /opt/backups
}

# ------------------------------------------------------------
# 💾 HÀM: Backup 1 domain cụ thể
# ------------------------------------------------------------
backup_domain() {
  local domain=$1
  local timestamp=$(date +%Y-%m-%d_%H-%M-%S)
  local web_root="/var/www/$domain"
  local backup_file="${BACKUP_ROOT}/${domain}_${timestamp}.tar.gz"

  if [ ! -d "$web_root" ]; then
    echo "⚠️  Không tìm thấy thư mục /var/www/$domain"
    return
  fi

  echo "➡️  Đang backup website: $domain ..."
  tar -czf "$backup_file" "$web_root" >/dev/null 2>&1
  echo "$(date '+%Y-%m-%d %H:%M:%S') | BACKUP SITE | $domain | $backup_file" >> "$LOG_FILE"
  echo "✅ Backup hoàn tất: $backup_file"
}

# ------------------------------------------------------------
# 🧠 HÀM: Backup toàn bộ website & database
# ------------------------------------------------------------
backup_all() {
  echo "=============================================="
  echo "💾 BẮT ĐẦU BACKUP TOÀN BỘ VPS $(date '+%Y-%m-%d %H:%M:%S')"
  echo "=============================================="

  init_backup_dir

  # Backup database (nếu MariaDB/MySQL đang chạy)
  if systemctl is-active --quiet mariadb || systemctl is-active --quiet mysql; then
    DB_FILE="${DB_BACKUP_DIR}/db_$(date +%Y-%m-%d_%H-%M-%S).sql.gz"
    mysqldump --all-databases | gzip > "$DB_FILE"
    echo "$(date '+%Y-%m-%d %H:%M:%S') | BACKUP DB | $DB_FILE" >> "$LOG_FILE"
    echo "✅ Backup database hoàn tất: $DB_FILE"
  else
    echo "⚠️  MariaDB/MySQL không chạy, bỏ qua backup DB."
  fi

  # Backup từng domain
  for site in /var/www/*; do
    [ -d "$site" ] || continue
    domain=$(basename "$site")
    backup_domain "$domain"
  done

  # Xóa backup cũ
  find "$BACKUP_ROOT" -type f -mtime +$KEEP_DAYS -delete
  find "$DB_BACKUP_DIR" -type f -mtime +$KEEP_DAYS -delete

  echo "✅ Dọn dẹp backup cũ hơn $KEEP_DAYS ngày."
  echo "=============================================="
  echo "🎯 Hoàn tất backup VPS!"
}

# ------------------------------------------------------------
# ⏰ HÀM: Tạo cron job tự động
# ------------------------------------------------------------
setup_cron_backup() {
  if ! crontab -l 2>/dev/null | grep -q backup_vps.sh; then
    cat <<'EOF' > /usr/local/bin/backup_vps.sh
#!/bin/bash
bash "$BASE_DIR/functions/backup.sh" auto >/dev/null 2>&1
EOF
    chmod +x /usr/local/bin/backup_vps.sh
    (crontab -l 2>/dev/null; echo "$CRON_SCHEDULE /usr/local/bin/backup_vps.sh") | crontab -
    echo "✅ Cron backup VPS đã được cài (chạy lúc 02:30 AM)."
  fi
}

# ------------------------------------------------------------
# 🚀 ENTRY POINT
# ------------------------------------------------------------
if [ "$1" == "auto" ]; then
  backup_all
  exit 0
fi

# Menu thủ công (gọi từ menu.sh)
clear
echo "💾 QUẢN LÝ BACKUP VPS"
echo "-------------------------------------------"
echo "1️⃣  Backup toàn bộ VPS"
echo "2️⃣  Backup website cụ thể"
echo "3️⃣  Cài cron auto backup"
echo "4️⃣  Xem log backup"
echo "5️⃣  Thoát"
read -p "👉 Chọn thao tác: " opt

case $opt in
  1) backup_all ;;
  2)
    read -p "Nhập domain: " domain
    backup_domain "$domain"
    ;;
  3) setup_cron_backup ;;
  4)
    tail -n 30 "$LOG_FILE"
    ;;
  5) exit 0 ;;
  *) echo "❌ Lựa chọn không hợp lệ." ;;
esac
