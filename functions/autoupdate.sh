#!/bin/bash
# ============================================================
# 🔄 MODULE: AUTO UPDATE SCRIPT ThanhTV VPS
# ------------------------------------------------------------
# Tác giả: ThanhTV
# Version: v2.0
# Mô tả:
#   - Tự động kiểm tra & cập nhật bản mới từ GitHub
#   - Backup bản cũ trước khi cập nhật
#   - Ghi log hoạt động vào /var/log/autoupdate.log
# ============================================================

# Set BASE_DIR correctly
if [ -z "$BASE_DIR" ]; then
  BASE_DIR="$(cd "$(dirname "$(dirname "$(realpath "$0")")")" && pwd)"
fi

LOG_FILE="$BASE_DIR/logs/autoupdate.log"
BACKUP_DIR="/opt/backups/script"
VERSION_FILE="$BASE_DIR/version.txt"

# ------------------------------------------------------------
# ⚙️ CONFIG GITHUB
# ------------------------------------------------------------
GITHUB_USER="duythanh18989"
GITHUB_REPO="thanhvps"
GITHUB_BRANCH="master"  # or "main"
GITHUB_RAW="https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/${GITHUB_BRANCH}"
REMOTE_VERSION_URL="${GITHUB_RAW}/version.txt"

# Load utils if available
if [ -f "$BASE_DIR/functions/utils.sh" ]; then
  source "$BASE_DIR/functions/utils.sh"
fi

# ------------------------------------------------------------
# 🧠 HÀM: Kiểm tra phiên bản hiện tại
# ------------------------------------------------------------
get_local_version() {
  if [ -f "$VERSION_FILE" ]; then
    cat "$VERSION_FILE" | tr -d '[:space:]'
  else
    echo "0.0.0"
  fi
}

# ------------------------------------------------------------
# 🧠 HÀM: Lấy version mới nhất từ GitHub
# ------------------------------------------------------------
get_remote_version() {
  local version=$(curl -fsSL "$REMOTE_VERSION_URL" 2>/dev/null | tr -d '[:space:]')
  if [ -z "$version" ]; then
    echo "0.0.0"
  else
    echo "$version"
  fi
}

# ------------------------------------------------------------
# 🔢 HÀM: So sánh version (semantic versioning)
# Return: 0 if equal, 1 if v1 < v2, 2 if v1 > v2
# ------------------------------------------------------------
compare_versions() {
  local v1=$1
  local v2=$2
  
  if [ "$v1" = "$v2" ]; then
    return 0
  fi
  
  # Split versions
  local IFS=.
  local i ver1=($v1) ver2=($v2)
  
  # Compare each part
  for ((i=0; i<${#ver1[@]} || i<${#ver2[@]}; i++)); do
    local num1=${ver1[i]:-0}
    local num2=${ver2[i]:-0}
    
    if ((10#$num1 > 10#$num2)); then
      return 2
    elif ((10#$num1 < 10#$num2)); then
      return 1
    fi
  done
  
  return 0
}

# ------------------------------------------------------------
# 💾 HÀM: Backup bản hiện tại
# ------------------------------------------------------------
backup_current_version() {
  mkdir -p "$BACKUP_DIR"
  local ts=$(date +%Y-%m-%d_%H-%M-%S)
  local tarfile="$BACKUP_DIR/thanhvps_${ts}.tar.gz"
  
  cd "$BASE_DIR"
  tar -czf "$tarfile" \
    --exclude='logs/*' \
    --exclude='.git' \
    --exclude='*.tar.gz' \
    --exclude='*.zip' \
    ./* 2>/dev/null
  
  if [ -f "$tarfile" ]; then
    log_info "✅ Backup: $tarfile"
    echo "$(date '+%Y-%m-%d %H:%M:%S') | BACKUP | $tarfile" >> "$LOG_FILE"
    return 0
  else
    log_warn "⚠️  Không thể tạo backup"
    return 1
  fi
}

# ------------------------------------------------------------
# 🚀 HÀM: Cập nhật script từ GitHub
# ------------------------------------------------------------
update_script() {
  log_info "🔄 Đang tải bản cập nhật từ GitHub..."
  
  TMP_DIR=$(mktemp -d)
  cd "$TMP_DIR"
  
  # Download entire repo as zip
  local zip_url="https://github.com/${GITHUB_USER}/${GITHUB_REPO}/archive/refs/heads/${GITHUB_BRANCH}.zip"
  
  if wget -q "$zip_url" -O repo.zip; then
    log_info "✅ Downloaded repo.zip"
    
    if unzip -q repo.zip; then
      log_info "✅ Extracted files"
      
      # Copy files to BASE_DIR (skip logs and .git)
      local extracted_dir="${TMP_DIR}/${GITHUB_REPO}-${GITHUB_BRANCH}"
      
      if [ -d "$extracted_dir" ]; then
        # Copy all files except logs and .git
        rsync -av --exclude='logs' --exclude='.git' "${extracted_dir}/" "$BASE_DIR/"
        
        # Make scripts executable
        chmod +x "$BASE_DIR"/*.sh
        chmod +x "$BASE_DIR"/functions/*.sh
        chmod +x "$BASE_DIR"/thanhvps
        
        # Update command
        if [ -f "$BASE_DIR/thanhvps" ]; then
          cp "$BASE_DIR/thanhvps" /usr/local/bin/thanhvps
          chmod +x /usr/local/bin/thanhvps
        fi
        
        log_info "✅ Files updated successfully"
        echo "$(date '+%Y-%m-%d %H:%M:%S') | UPDATE SUCCESS | $REMOTE_VERSION" >> "$LOG_FILE"
        
        # Clean up
        cd "$BASE_DIR"
        rm -rf "$TMP_DIR"
        
        return 0
      else
        log_error "❌ Extracted directory not found"
        return 1
      fi
    else
      log_error "❌ Failed to extract"
      return 1
    fi
  else
    log_error "❌ Failed to download"
    return 1
  fi
}

# ------------------------------------------------------------
# 🧩 MAIN LOGIC
# ------------------------------------------------------------
main() {
  clear
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🔄 ThanhTV VPS Auto Update"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  
  LOCAL_VERSION=$(get_local_version)
  REMOTE_VERSION=$(get_remote_version)
  
  log_info "📦 Phiên bản hiện tại: $LOCAL_VERSION"
  log_info "📦 Phiên bản mới nhất: $REMOTE_VERSION"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  
  # Check if remote version is valid
  if [ "$REMOTE_VERSION" = "0.0.0" ]; then
    log_error "❌ Không thể kết nối GitHub để kiểm tra version"
    log_info "URL: $REMOTE_VERSION_URL"
    exit 1
  fi
  
  # Compare versions
  compare_versions "$LOCAL_VERSION" "$REMOTE_VERSION"
  result=$?
  
  if [ $result -eq 0 ]; then
    log_info "✅ Bạn đang sử dụng phiên bản mới nhất!"
    exit 0
  elif [ $result -eq 2 ]; then
    log_warn "⚠️  Phiên bản local ($LOCAL_VERSION) mới hơn remote ($REMOTE_VERSION)"
    log_info "Đang dev version? Bỏ qua update."
    exit 0
  fi
  
  # Need update
  echo ""
  log_warn "⚠️  Có bản cập nhật mới: $LOCAL_VERSION → $REMOTE_VERSION"
  echo ""
  
  if command_exists gum; then
    if gum confirm "Bạn có muốn cập nhật không?"; then
      DO_UPDATE=true
    else
      DO_UPDATE=false
    fi
  else
    read -p "👉 Bạn có muốn cập nhật không? (y/n): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
      DO_UPDATE=true
    else
      DO_UPDATE=false
    fi
  fi
  
  if [ "$DO_UPDATE" = true ]; then
    echo ""
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "🚀 BẮT ĐẦU CẬP NHẬT"
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Backup first
    backup_current_version
    
    # Update
    if update_script; then
      echo ""
      log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      log_info "🎉 CẬP NHẬT THÀNH CÔNG!"
      log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      log_info "📦 Version mới: $REMOTE_VERSION"
      log_info "📝 Xem thay đổi: cat CHANGELOG.md"
      echo ""
    else
      echo ""
      log_error "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      log_error "❌ CẬP NHẬT THẤT BẠI"
      log_error "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      log_info "💾 Backup vẫn còn tại: $BACKUP_DIR"
      echo ""
    fi
  else
    log_info "❌ Đã hủy cập nhật"
  fi
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main
fi

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
