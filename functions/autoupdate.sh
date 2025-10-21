#!/bin/bash
# ============================================================
# 🔄 MODULE: AUTO UPDATE SCRIPT ThanhTV VPS
# ------------------------------------------------------------
# Tác giả: ThanhTV
# Version: v1.0
# Mô tả:
#   - Tự động kiểm tra & cập nhật bản mới từ GitHub
#   - Backup bản cũ trước khi cập nhật
#   - Ghi log hoạt động vào /var/log/autoupdate.log
# ============================================================

BASE_DIR=$(dirname "$(realpath "$0")")/..
LOG_FILE="/var/log/autoupdate.log"
BACKUP_DIR="/opt/backups/script"
VERSION_FILE="$BASE_DIR/version.txt"

# ------------------------------------------------------------
# ⚙️ CONFIG GITHUB (chỉnh theo repo thật của anh)
# ------------------------------------------------------------
GITHUB_REPO="https://raw.githubusercontent.com/duythanh18989/thanhvps/main"
REMOTE_VERSION_URL="$GITHUB_REPO/version.txt"

# ------------------------------------------------------------
# 🧠 HÀM: Kiểm tra phiên bản hiện tại
# ------------------------------------------------------------
get_local_version() {
  if [ -f "$VERSION_FILE" ]; then
    cat "$VERSION_FILE"
  else
    echo "0.0.0"
  fi
}

# ------------------------------------------------------------
# 🧠 HÀM: Lấy version mới nhất từ GitHub
# ------------------------------------------------------------
get_remote_version() {
  curl -fsSL "$REMOTE_VERSION_URL" 2>/dev/null || echo "0.0.0"
}

# ------------------------------------------------------------
# 💾 HÀM: Backup bản hiện tại
# ------------------------------------------------------------
backup_current_version() {
  mkdir -p "$BACKUP_DIR"
  local ts=$(date +%Y-%m-%d_%H-%M-%S)
  local zipfile="$BACKUP_DIR/ThanhTV_VPS_${ts}.zip"
  cd "$BASE_DIR"
  zip -qr "$zipfile" ./*
  echo "✅ Backup script hiện tại: $zipfile"
  echo "$(date '+%Y-%m-%d %H:%M:%S') | BACKUP | $zipfile" >> "$LOG_FILE"
}

# ------------------------------------------------------------
# 🚀 HÀM: Cập nhật script từ GitHub
# ------------------------------------------------------------
update_script() {
  echo "🔄 Đang tải bản cập nhật từ GitHub..."
  TMP_DIR=$(mktemp -d)
  cd "$TMP_DIR"

  # Danh sách file cần update
  FILES=("install.sh" "menu.sh" "version.txt")

  # Tải từng file
  for f in "${FILES[@]}"; do
    curl -fsSLO "$GITHUB_REPO/$f" && mv "$f" "$BASE_DIR/$f"
  done

  # Tải toàn bộ functions
  mkdir -p "$BASE_DIR/functions"
  curl -fsSL "$GITHUB_REPO/functions.list" -o "$TMP_DIR/functions.list"
  while read -r func; do
    [ -z "$func" ] && continue
    curl -fsSLO "$GITHUB_REPO/functions/$func" && mv "$func" "$BASE_DIR/functions/$func"
  done < "$TMP_DIR/functions.list"

  echo "$(date '+%Y-%m-%d %H:%M:%S') | UPDATE SUCCESS | $REMOTE_VERSION" >> "$LOG_FILE"
  echo "✅ Cập nhật hoàn tất! Đã lên version $REMOTE_VERSION"
}

# ------------------------------------------------------------
# 🧩 MAIN LOGIC
# ------------------------------------------------------------
LOCAL_VERSION=$(get_local_version)
REMOTE_VERSION=$(get_remote_version)

echo "=============================================="
echo "🔄 ThanhTV VPS Auto Update"
echo "=============================================="
echo "🔹 Phiên bản hiện tại: $LOCAL_VERSION"
echo "🔸 Phiên bản mới nhất: $REMOTE_VERSION"
echo "=============================================="

if [ "$REMOTE_VERSION" = "$LOCAL_VERSION" ]; then
  echo "✅ Bạn đang dùng bản mới nhất!"
  exit 0
fi

echo "⚠️  Có bản cập nhật mới ($REMOTE_VERSION > $LOCAL_VERSION)."
read -p "👉 Bạn có muốn cập nhật không (y/n)? " confirm
if [[ "$confirm" =~ ^[Yy]$ ]]; then
  backup_current_version
  update_script
else
  echo "❌ Bỏ qua cập nhật."
fi
