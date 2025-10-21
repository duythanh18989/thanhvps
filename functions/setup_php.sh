#!/bin/bash
# ========================================================
# 🐘 setup_php.sh - Cài PHP đa phiên bản (cập nhật)
# ========================================================

install_php() {
  log_info "Đang cài PHP (đa version)..."

  # Thêm PPA Ondrej PHP nếu chưa có
  if ! grep -q "ondrej/php" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
    add-apt-repository ppa:ondrej/php -y >/dev/null
    apt-get update -y >/dev/null
  fi

  # Các phiên bản PHP cần cài
  PHP_VERSIONS=("7.4" "8.1" "8.2" "8.3")

  for ver in "${PHP_VERSIONS[@]}"; do
    # Kiểm tra PHP đã cài chưa
    if ! command -v php$ver >/dev/null 2>&1; then
      log_info "Cài PHP $ver..."
      apt-get install -y php$ver php$ver-fpm php$ver-mysql php$ver-cli php$ver-curl php$ver-xml php$ver-zip php$ver-mbstring >/dev/null
    else
      log_info "PHP $ver đã cài, bỏ qua"
    fi

    # Kiểm tra service tồn tại trước khi enable/start
    if systemctl list-unit-files | grep -q "php$ver-fpm.service"; then
      systemctl enable php$ver-fpm
      systemctl restart php$ver-fpm
      log_info "✅ PHP $ver-FPM đã enable/start"
    else
      log_warn "⚠️ PHP $ver-FPM service không tồn tại, bỏ qua"
    fi
  done

  log_info "🎉 Hoàn tất cài PHP phiên bản: ${PHP_VERSIONS[*]}"
}
