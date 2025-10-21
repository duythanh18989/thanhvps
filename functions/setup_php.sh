#!/bin/bash
# ========================================================
# 🐘 setup_php.sh - Cài PHP đa phiên bản
# Version: 2.0
# ========================================================

install_php() {
  log_info "Đang cài đặt PHP (đa phiên bản)..."
  
  # Chờ apt lock được giải phóng
  wait_for_apt
  
  # Cài đặt dependencies cần thiết
  log_info "Cài đặt dependencies..."
  apt-get install -y software-properties-common apt-transport-https ca-certificates curl &>/dev/null
  
  # Thêm PPA Ondrej PHP nếu chưa có
  if ! grep -q "ondrej/php" /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null; then
    log_info "Thêm PPA ondrej/php..."
    if ! add-apt-repository ppa:ondrej/php -y &>/dev/null; then
      log_error "Không thể thêm PPA ondrej/php. Kiểm tra kết nối mạng!"
      return 1
    fi
    
    log_info "Cập nhật package list..."
    if ! apt-get update -y &>/dev/null; then
      log_error "Lỗi khi cập nhật apt!"
      return 1
    fi
  else
    log_info "PPA ondrej/php đã tồn tại"
  fi
  
  # Lấy danh sách PHP versions từ config hoặc dùng mặc định
  if [ -n "$CONFIG_php_versions" ]; then
    # Parse từ config (format: "7.4 8.1 8.2 8.3")
    IFS=' ' read -ra PHP_VERSIONS <<< "$CONFIG_php_versions"
  else
    # Default versions
    PHP_VERSIONS=("7.4" "8.1" "8.2" "8.3")
  fi
  
  log_info "Sẽ cài các phiên bản PHP: ${PHP_VERSIONS[*]}"
  
  # Danh sách extensions cần thiết
  local COMMON_EXTENSIONS=(
    "fpm"
    "cli"
    "common"
    "mysql"
    "mysqli"
    "pdo"
    "curl"
    "gd"
    "mbstring"
    "xml"
    "zip"
    "bcmath"
    "json"
    "intl"
    "soap"
    "imagick"
    "redis"
  )
  
  # Cài đặt từng phiên bản PHP
  for ver in "${PHP_VERSIONS[@]}"; do
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "📦 Đang cài PHP ${ver}..."
    
    # Kiểm tra PHP đã cài chưa
    if command_exists "php${ver}"; then
      log_info "PHP ${ver} đã được cài đặt, kiểm tra extensions..."
    else
      log_info "Cài đặt PHP ${ver} và extensions..."
    fi
    
    # Build package list
    local packages="php${ver}"
    for ext in "${COMMON_EXTENSIONS[@]}"; do
      # Một số extension không có cho mọi version
      if apt-cache show "php${ver}-${ext}" &>/dev/null; then
        packages="$packages php${ver}-${ext}"
      fi
    done
    
    # Install packages
    if ! apt-get install -y $packages &>/dev/null; then
      log_error "Lỗi khi cài PHP ${ver}. Bỏ qua..."
      continue
    fi
    
    # Configure PHP-FPM
    local fpm_conf="/etc/php/${ver}/fpm/php.ini"
    if [ -f "$fpm_conf" ]; then
      log_info "Cấu hình PHP ${ver}-FPM..."
      
      # Tối ưu cấu hình PHP
      sed -i 's/upload_max_filesize = .*/upload_max_filesize = 128M/' "$fpm_conf"
      sed -i 's/post_max_size = .*/post_max_size = 128M/' "$fpm_conf"
      sed -i 's/memory_limit = .*/memory_limit = 256M/' "$fpm_conf"
      sed -i 's/max_execution_time = .*/max_execution_time = 300/' "$fpm_conf"
      sed -i 's/;date.timezone =.*/date.timezone = Asia\/Ho_Chi_Minh/' "$fpm_conf"
      
      # Enable opcache
      sed -i 's/;opcache.enable=.*/opcache.enable=1/' "$fpm_conf"
      sed -i 's/;opcache.memory_consumption=.*/opcache.memory_consumption=128/' "$fpm_conf"
    fi
    
    # Enable và start service
    local service_name="php${ver}-fpm"
    if systemctl list-unit-files | grep -q "${service_name}.service"; then
      systemctl enable "$service_name" &>/dev/null
      systemctl restart "$service_name" &>/dev/null
      
      if service_is_active "$service_name"; then
        log_info "✅ PHP ${ver}-FPM đang chạy"
      else
        log_error "Không thể khởi động PHP ${ver}-FPM"
      fi
    else
      log_warn "Service ${service_name} không tồn tại"
    fi
  done
  
  log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  log_info "🎉 Hoàn tất cài đặt PHP!"
  log_info "📋 Các phiên bản đã cài: ${PHP_VERSIONS[*]}"
  
  # Set default PHP version (latest)
  local latest_php="${PHP_VERSIONS[-1]}"
  if command_exists "update-alternatives"; then
    update-alternatives --set php "/usr/bin/php${latest_php}" &>/dev/null
    log_info "🔧 PHP CLI mặc định: ${latest_php}"
  fi
  
  return 0
}
