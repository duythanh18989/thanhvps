#!/bin/bash
# ========================================================
# ⚙️  utils.sh - Hàm tiện ích dùng chung
# ========================================================

# Hàm log
log_info()  { echo -e "✅ [INFO] $1"; }
log_error() { echo -e "❌ [ERROR] $1"; }

# Random password
random_password() {
  tr -dc A-Za-z0-9 </dev/urandom | head -c 16
}

# Kiểm tra OS hợp lệ
check_os() {
  if ! grep -q "Ubuntu 22.04" /etc/os-release; then
    log_error "Script này chỉ hỗ trợ Ubuntu 22.04 LTS!"
    exit 1
  fi
}

# Parser YAML đơn giản (dùng awk)
# Gọi: parse_yaml file prefix_
parse_yaml() {
  local prefix=$2
  local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs
  fs=$(echo @|tr @ '\034')
  sed -ne "s|^\($s\):|\1|" \
      -e "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
      -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p" "$1" |
  awk -F"$fs" '{
    indent = length($1)/2;
    vname[indent] = $2;
    for (i in vname) if (i > indent) delete vname[i];
    if (length($3) > 0) {
      vn=""; for (i=0; i<indent; i++) vn=(vn)(vname[i])("_");
      printf("%s%s%s=\"%s\"\n", "'$prefix'", vn, $2, $3);
    }
  }'
}

# Kiểm tra & cài gum (nếu chưa có)
check_gum() {
  if ! command -v gum &>/dev/null; then
    log_info "Đang cài gum..."
    wget -q https://github.com/charmbracelet/gum/releases/latest/download/gum_0.13.0_amd64.deb -O /tmp/gum.deb
    dpkg -i /tmp/gum.deb &>/dev/null || apt-get install -f -y
  fi
}
