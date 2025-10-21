#!/bin/bash
# ========================================================
# 🔴 setup_redis.sh - Cài đặt Redis Server
# Version: 1.0
# ========================================================

install_redis() {
  log_info "Đang cài đặt Redis Server..."
  
  # Kiểm tra xem Redis đã được cài chưa
  if command_exists redis-server; then
    log_info "Redis đã được cài đặt"
    if service_is_active redis-server; then
      log_info "✅ Redis đang chạy"
      redis-cli --version
      return 0
    fi
  fi
  
  # Chờ apt lock
  wait_for_apt
  
  # Cài đặt Redis
  log_info "Cài đặt Redis từ apt..."
  if ! apt-get install -y redis-server &>/dev/null; then
    log_error "Không thể cài đặt Redis!"
    return 1
  fi
  
  # Lấy cấu hình từ config.yml
  local redis_port=${CONFIG_redis_port:-6379}
  local redis_maxmemory=${CONFIG_redis_maxmemory:-256mb}
  local redis_policy=${CONFIG_redis_maxmemory_policy:-allkeys-lru}
  
  log_info "Cấu hình Redis..."
  
  # Backup file config gốc
  if [ -f /etc/redis/redis.conf ]; then
    cp /etc/redis/redis.conf /etc/redis/redis.conf.bak
  fi
  
  # Cấu hình Redis
  local redis_conf="/etc/redis/redis.conf"
  
  # Cho phép kết nối từ localhost
  sed -i 's/^bind .*/bind 127.0.0.1 ::1/' "$redis_conf"
  
  # Set port
  sed -i "s/^port .*/port $redis_port/" "$redis_conf"
  
  # Set maxmemory
  if ! grep -q "^maxmemory" "$redis_conf"; then
    echo "maxmemory $redis_maxmemory" >> "$redis_conf"
  else
    sed -i "s/^maxmemory .*/maxmemory $redis_maxmemory/" "$redis_conf"
  fi
  
  # Set maxmemory-policy
  if ! grep -q "^maxmemory-policy" "$redis_conf"; then
    echo "maxmemory-policy $redis_policy" >> "$redis_conf"
  else
    sed -i "s/^maxmemory-policy .*/maxmemory-policy $redis_policy/" "$redis_conf"
  fi
  
  # Enable supervised systemd
  sed -i 's/^supervised .*/supervised systemd/' "$redis_conf"
  
  # Disable RDB persistence (optional, for cache-only usage)
  # sed -i 's/^save/# save/' "$redis_conf"
  
  # Enable và start Redis
  systemctl enable redis-server &>/dev/null
  systemctl restart redis-server
  
  # Kiểm tra Redis
  sleep 2
  if service_is_active redis-server; then
    log_info "✅ Redis đã được cài đặt và đang chạy"
    log_info "📋 Port: $redis_port"
    log_info "💾 Max Memory: $redis_maxmemory"
    log_info "🔧 Policy: $redis_policy"
    
    # Test connection
    if redis-cli ping &>/dev/null; then
      log_info "✅ Redis connection OK"
    else
      log_warn "⚠️  Không thể kết nối Redis"
    fi
  else
    log_error "❌ Redis service không chạy được"
    return 1
  fi
  
  # Ghi log
  echo "$(date '+%Y-%m-%d %H:%M:%S') | INSTALL REDIS | Port: $redis_port" >> "$BASE_DIR/logs/install.log"
  
  return 0
}

# Configure Redis for PHP sessions (optional)
configure_redis_php_sessions() {
  local php_ver=${1:-8.2}
  
  log_info "Cấu hình PHP ${php_ver} sử dụng Redis cho sessions..."
  
  local php_ini="/etc/php/${php_ver}/fpm/php.ini"
  
  if [ ! -f "$php_ini" ]; then
    log_warn "Không tìm thấy php.ini cho PHP ${php_ver}"
    return 1
  fi
  
  # Configure session handler
  sed -i 's/^session.save_handler = .*/session.save_handler = redis/' "$php_ini"
  sed -i 's|^;session.save_path = .*|session.save_path = "tcp://127.0.0.1:6379"|' "$php_ini"
  
  # Restart PHP-FPM
  systemctl restart "php${php_ver}-fpm" &>/dev/null
  
  log_info "✅ PHP ${php_ver} đã được cấu hình sử dụng Redis"
}

# Show Redis info
redis_info() {
  if ! command_exists redis-cli; then
    log_error "Redis chưa được cài đặt"
    return 1
  fi
  
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🔴 REDIS SERVER INFO"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  redis-cli INFO | grep -E "redis_version|uptime_in_days|connected_clients|used_memory_human|maxmemory_human"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Flush Redis cache
redis_flush() {
  if confirm "⚠️  Xóa toàn bộ cache Redis?"; then
    redis-cli FLUSHALL
    log_info "✅ Redis cache đã được xóa"
  fi
}
