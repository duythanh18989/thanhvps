#!/bin/bash
# ========================================================
# 🔐 setup_ssl.sh - Auto cấp SSL Let's Encrypt
# ========================================================

install_ssl() {
  local DOMAIN=$1

  if [ "$CONFIG_ssl_auto_ssl" = "true" ]; then
    log_info "Đang cài đặt SSL cho $DOMAIN..."
    apt-get install -y certbot python3-certbot-nginx &>/dev/null
    certbot --nginx -d $DOMAIN --non-interactive --agree-tos -m admin@$DOMAIN || log_error "Không thể cấp SSL (domain có thể chưa trỏ DNS)."
  else
    log_info "Bỏ qua SSL (ssl_auto_ssl=false)."
  fi
}
