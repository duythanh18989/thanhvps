#!/bin/bash
# ========================================================
# 🗄️ setup_phpmyadmin.sh - Install phpMyAdmin
# ========================================================

install_phpmyadmin() {
  log_info "🗄️ Đang cài phpMyAdmin..."
  
  # Install dependencies
  apt-get install -y wget unzip php-mbstring php-zip php-gd php-json php-curl &>/dev/null
  
  # Get latest version
  PHPMYADMIN_VERSION="5.2.1"
  PMA_DIR="/var/www/phpmyadmin"
  
  # Download phpMyAdmin
  cd /tmp
  wget -q "https://files.phpmyadmin.net/phpMyAdmin/${PHPMYADMIN_VERSION}/phpMyAdmin-${PHPMYADMIN_VERSION}-all-languages.zip" -O phpmyadmin.zip
  
  if [ ! -f "phpmyadmin.zip" ]; then
    log_error "❌ Failed to download phpMyAdmin"
    return 1
  fi
  
  # Extract
  unzip -q phpmyadmin.zip
  rm -rf "$PMA_DIR"
  mv "phpMyAdmin-${PHPMYADMIN_VERSION}-all-languages" "$PMA_DIR"
  rm -f phpmyadmin.zip
  
  # Set permissions
  chown -R www-data:www-data "$PMA_DIR"
  chmod -R 755 "$PMA_DIR"
  
  # Create config
  cat > "$PMA_DIR/config.inc.php" <<'EOF'
<?php
declare(strict_types=1);

$cfg['blowfish_secret'] = '$(openssl rand -base64 32)';

$i = 0;
$i++;
$cfg['Servers'][$i]['auth_type'] = 'cookie';
$cfg['Servers'][$i]['host'] = 'localhost';
$cfg['Servers'][$i]['compress'] = false;
$cfg['Servers'][$i]['AllowNoPassword'] = false;

$cfg['UploadDir'] = '';
$cfg['SaveDir'] = '';
$cfg['TempDir'] = '/tmp';

// Security
$cfg['LoginCookieValidity'] = 3600;
$cfg['LoginCookieStore'] = 0;
EOF
  
  # Create Nginx vhost for phpMyAdmin
  local PMA_DOMAIN=${CONFIG_phpmyadmin_domain:-pma.$(hostname -f)}
  local PMA_PORT=${CONFIG_phpmyadmin_port:-8081}
  
  # Option 1: Subdomain
  if [ "$CONFIG_phpmyadmin_mode" = "subdomain" ] && [ -n "$CONFIG_phpmyadmin_domain" ]; then
    cat > /etc/nginx/sites-available/phpmyadmin.conf <<EOF
server {
    listen 80;
    server_name $PMA_DOMAIN;
    root $PMA_DIR;
    index index.php;
    
    access_log /var/log/nginx/phpmyadmin-access.log;
    error_log /var/log/nginx/phpmyadmin-error.log;
    
    location / {
        try_files \$uri \$uri/ =404;
    }
    
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.2-fpm.sock;
    }
    
    location ~ /\.ht {
        deny all;
    }
}
EOF
    ln -sf /etc/nginx/sites-available/phpmyadmin.conf /etc/nginx/sites-enabled/
    log_info "✅ phpMyAdmin: http://$PMA_DOMAIN"
    
  # Option 2: Port-based
  else
    cat > /etc/nginx/sites-available/phpmyadmin.conf <<EOF
server {
    listen $PMA_PORT;
    server_name _;
    root $PMA_DIR;
    index index.php;
    
    access_log /var/log/nginx/phpmyadmin-access.log;
    error_log /var/log/nginx/phpmyadmin-error.log;
    
    location / {
        try_files \$uri \$uri/ =404;
    }
    
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.2-fpm.sock;
    }
    
    location ~ /\.ht {
        deny all;
    }
}
EOF
    ln -sf /etc/nginx/sites-available/phpmyadmin.conf /etc/nginx/sites-enabled/
    local SERVER_IP=$(hostname -I | awk '{print $1}')
    log_info "✅ phpMyAdmin: http://$SERVER_IP:$PMA_PORT"
  fi
  
  # Reload Nginx
  nginx -t && systemctl reload nginx
  
  log_info "✅ phpMyAdmin installed successfully!"
  log_info "📝 Login with MySQL root credentials"
}

# Uninstall phpMyAdmin
uninstall_phpmyadmin() {
  log_info "Removing phpMyAdmin..."
  
  rm -rf /var/www/phpmyadmin
  rm -f /etc/nginx/sites-enabled/phpmyadmin.conf
  rm -f /etc/nginx/sites-available/phpmyadmin.conf
  
  systemctl reload nginx
  
  log_info "✅ phpMyAdmin removed"
}
