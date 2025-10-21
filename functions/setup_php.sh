#!/bin/bash
# ========================================================
# 🐘 setup_php.sh - Cài PHP đa phiên bản
# ========================================================

install_php() {
  log_info "Đang cài PHP (đa version)..."

  add-apt-repository ppa:ondrej/php -y >/dev/null
  apt-get update -y >/dev/null

  for ver in 7.4 8.1 8.2 8.3; do
    apt-get install -y php$ver php$ver-fpm php$ver-mysql php$ver-cli php$ver-curl php$ver-xml php$ver-zip php$ver-mbstring >/dev/null
    systemctl enable php$ver-fpm
    systemctl start php$ver-fpm
  done

  log_info "✅ Đã cài xong các phiên bản PHP: 7.4, 8.1, 8.2, 8.3"
}
