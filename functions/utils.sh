#!/bin/bash
# ========================================================
# ⚙️  utils.sh - Hàm tiện ích dùng chung
# Version: 2.0
# ========================================================

# === COLOR CODES ===
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# === LOGGING FUNCTIONS ===
log_info()  { echo -e "${GREEN}✅ [INFO]${NC} $1"; }
log_error() { echo -e "${RED}❌ [ERROR]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}⚠️  [WARN]${NC} $1"; }
log_debug() { 
  if [ "${DEBUG_MODE}" = "true" ]; then
    echo -e "${BLUE}🔍 [DEBUG]${NC} $1"
  fi
}

# === UTILITY FUNCTIONS ===

# Random password generator
random_password() {
  local length=${1:-16}
  tr -dc 'A-Za-z0-9!@#$%^&*' </dev/urandom | head -c "$length"
}

# Check if script is run as root
check_root() {
  if [ "$EUID" -ne 0 ]; then
    log_error "Vui lòng chạy script bằng quyền root (sudo su)."
    exit 1
  fi
}

# Kiểm tra OS hợp lệ (hỗ trợ Ubuntu 20.04, 22.04, 24.04)
check_os() {
  if ! grep -Eq "Ubuntu (20|22|24)\.04" /etc/os-release; then
    log_warn "Script được thiết kế cho Ubuntu 20.04/22.04/24.04 LTS!"
    read -p "Bạn có muốn tiếp tục? (y/n): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
      exit 1
    fi
  else
    log_info "OS: $(grep PRETTY_NAME /etc/os-release | cut -d'=' -f2 | tr -d '\"')"
  fi
}

# Check if command exists
command_exists() {
  command -v "$1" &>/dev/null
}

# Check if service is active
service_is_active() {
  systemctl is-active --quiet "$1"
}

# Wait for apt lock
wait_for_apt() {
  while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 ; do
    log_warn "Đang đợi apt lock được giải phóng..."
    sleep 2
  done
}

# === YAML PARSER ===
# Improved YAML parser with better error handling
# Usage: parse_yaml config.yml "CONFIG_"
parse_yaml() {
  local yaml_file=$1
  local prefix=$2
  
  if [ ! -f "$yaml_file" ]; then
    log_error "File YAML không tồn tại: $yaml_file"
    return 1
  fi
  
  local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs
  fs=$(echo @|tr @ '\034')
  
  sed -ne "s|^\($s\):|\1|" \
      -e "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
      -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p" "$yaml_file" |
  awk -F"$fs" '{
    indent = length($1)/2;
    vname[indent] = $2;
    for (i in vname) if (i > indent) delete vname[i];
    if (length($3) > 0) {
      vn=""; for (i=0; i<indent; i++) vn=(vn)(vname[i])("_");
      printf("export %s%s%s=\"%s\"\n", "'"$prefix"'", vn, $2, $3);
    }
  }' | bash
}

# Read single value from YAML
read_yaml_value() {
  local file=$1
  local key=$2
  grep "^${key}:" "$file" | head -n1 | cut -d':' -f2- | xargs
}

# === GUM INSTALLATION ===
check_gum() {
  if ! command_exists gum; then
    log_info "Đang cài gum (TUI framework)..."
    
    # Detect architecture
    local ARCH=$(uname -m)
    case $ARCH in
      x86_64)  ARCH="amd64" ;;
      aarch64) ARCH="arm64" ;;
      armv7l)  ARCH="armv7" ;;
      *)
        log_warn "Kiến trúc $ARCH không được hỗ trợ, bỏ qua cài gum."
        return 1
        ;;
    esac
    
    wget -q "https://github.com/charmbracelet/gum/releases/latest/download/gum_0.13.0_${ARCH}.deb" -O /tmp/gum.deb
    
    if [ -f /tmp/gum.deb ]; then
      dpkg -i /tmp/gum.deb &>/dev/null || apt-get install -f -y &>/dev/null
      rm -f /tmp/gum.deb
      log_info "✅ Gum đã được cài đặt"
    else
      log_warn "Không thể tải gum, sử dụng UI cơ bản."
    fi
  fi
}

# === CONFIRMATION PROMPT ===
confirm() {
  local message=${1:-"Bạn có chắc chắn?"}
  if command_exists gum; then
    gum confirm "$message"
  else
    read -p "$message (y/n): " confirm
    [[ "$confirm" =~ ^[Yy]$ ]]
  fi
}

# === SPINNER FOR LONG TASKS ===
run_with_spinner() {
  local message=$1
  shift
  local cmd="$@"
  
  if command_exists gum; then
    gum spin --spinner dot --title "$message" -- bash -c "$cmd"
  else
    echo -n "$message "
    eval "$cmd" &
    local pid=$!
    while kill -0 $pid 2>/dev/null; do
      echo -n "."
      sleep 1
    done
    echo " Done"
    wait $pid
  fi
}
