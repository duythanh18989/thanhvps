#!/bin/bash
# ========================================================
# 🚀 deploy.sh - Deploy website NodeJS/PHP với Nginx
# ========================================================

# Deploy NodeJS app
deploy_nodejs_app() {
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🚀 DEPLOY NODEJS APP"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  # Check NodeJS
  if ! command_exists node; then
    log_error "❌ NodeJS chưa được cài đặt. Vui lòng cài NodeJS trước."
    return 1
  fi
  
  # Input domain
  if $use_gum; then
    domain=$(gum input --placeholder "Nhập domain (vd: api.example.com)")
    app_name=$(gum input --placeholder "Nhập tên app (vd: my-api)" --value "${domain//./-}")
    git_repo=$(gum input --placeholder "Git repository URL (optional, Enter để skip)")
    app_port=$(gum input --placeholder "Port NodeJS app (mặc định: 3000)" --value "3000")
  else
    read -p "Nhập domain: " domain
    read -p "Nhập tên app [${domain//./-}]: " app_name
    app_name=${app_name:-${domain//./-}}
    read -p "Git repository URL (Enter để skip): " git_repo
    read -p "Port NodeJS app [3000]: " app_port
    app_port=${app_port:-3000}
  fi
  
  if [ -z "$domain" ]; then
    log_error "❌ Domain không được để trống"
    return 1
  fi
  
  # App directory
  APP_DIR="/var/www/$domain"
  
  # Create directory
  if [ -n "$git_repo" ]; then
    log_info "📥 Clone repository từ Git..."
    rm -rf "$APP_DIR"
    git clone "$git_repo" "$APP_DIR" || {
      log_error "❌ Không thể clone repository"
      return 1
    }
  else
    if [ ! -d "$APP_DIR" ]; then
      log_info "📁 Tạo thư mục $APP_DIR"
      mkdir -p "$APP_DIR"
      
      # Create sample app
      cat > "$APP_DIR/server.js" <<'EOF'
const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.json({
    message: 'Hello from NodeJS!',
    timestamp: new Date().toISOString()
  });
});

app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});
EOF
      
      cat > "$APP_DIR/package.json" <<EOF
{
  "name": "$app_name",
  "version": "1.0.0",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.18.2"
  }
}
EOF
      
      log_info "✅ Đã tạo sample NodeJS app"
    else
      log_info "📁 Thư mục $APP_DIR đã tồn tại"
    fi
  fi
  
  # Install dependencies
  if [ -f "$APP_DIR/package.json" ]; then
    log_info "📦 Cài đặt dependencies..."
    cd "$APP_DIR" && npm install --production &>/dev/null
  fi
  
  # Create Nginx config
  log_info "🔧 Cấu hình Nginx reverse proxy..."
  
  cat > "/etc/nginx/sites-available/$domain.conf" <<EOF
server {
    listen 80;
    server_name $domain;
    
    access_log /var/log/nginx/${domain}-access.log;
    error_log /var/log/nginx/${domain}-error.log;
    
    location / {
        proxy_pass http://127.0.0.1:${app_port};
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF
  
  ln -sf "/etc/nginx/sites-available/$domain.conf" "/etc/nginx/sites-enabled/"
  
  # Test Nginx
  if ! nginx -t &>/dev/null; then
    log_error "❌ Nginx config có lỗi"
    return 1
  fi
  
  systemctl reload nginx
  
  # Start app with PM2
  log_info "🚀 Khởi động app với PM2..."
  
  # Load NVM
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  
  cd "$APP_DIR"
  
  # Stop old instance if exists
  pm2 delete "$app_name" 2>/dev/null
  
  # Start new instance
  pm2 start server.js --name "$app_name" -i 1 --env production
  pm2 save
  
  echo ""
  log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  log_info "✅ DEPLOY THÀNH CÔNG!"
  log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  log_info "🌐 Domain: http://$domain"
  log_info "📁 App dir: $APP_DIR"
  log_info "🔧 PM2 app: $app_name"
  log_info "📊 Status: pm2 status"
  log_info "📝 Logs: pm2 logs $app_name"
  log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Deploy PHP website
deploy_php_website() {
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🚀 DEPLOY PHP WEBSITE"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  # Check PHP
  if ! command_exists php; then
    log_error "❌ PHP chưa được cài đặt"
    return 1
  fi
  
  # Input domain
  if $use_gum; then
    domain=$(gum input --placeholder "Nhập domain (vd: example.com)")
    git_repo=$(gum input --placeholder "Git repository URL (optional)")
    php_version=$(gum choose "8.3" "8.2" "8.1" "7.4")
  else
    read -p "Nhập domain: " domain
    read -p "Git repository URL (Enter để skip): " git_repo
    echo "Chọn PHP version:"
    echo "1) 8.3"
    echo "2) 8.2"
    echo "3) 8.1"
    echo "4) 7.4"
    read -p "Chọn [2]: " php_choice
    case "$php_choice" in
      1) php_version="8.3" ;;
      3) php_version="8.1" ;;
      4) php_version="7.4" ;;
      *) php_version="8.2" ;;
    esac
  fi
  
  if [ -z "$domain" ]; then
    log_error "❌ Domain không được để trống"
    return 1
  fi
  
  # Website directory
  SITE_DIR="/var/www/$domain"
  
  # Create directory
  if [ -n "$git_repo" ]; then
    log_info "📥 Clone repository từ Git..."
    rm -rf "$SITE_DIR"
    git clone "$git_repo" "$SITE_DIR" || {
      log_error "❌ Không thể clone repository"
      return 1
    }
  else
    if [ ! -d "$SITE_DIR" ]; then
      log_info "📁 Tạo thư mục $SITE_DIR"
      mkdir -p "$SITE_DIR"
      
      # Create sample index.php
      cat > "$SITE_DIR/index.php" <<'EOF'
<?php
phpinfo();
?>
EOF
      
      log_info "✅ Đã tạo sample PHP website"
    else
      log_info "📁 Thư mục $SITE_DIR đã tồn tại"
    fi
  fi
  
  # Set permissions
  chown -R www-data:www-data "$SITE_DIR"
  chmod -R 755 "$SITE_DIR"
  
  # Create Nginx config
  log_info "🔧 Cấu hình Nginx..."
  
  cat > "/etc/nginx/sites-available/$domain.conf" <<EOF
server {
    listen 80;
    server_name $domain www.$domain;
    root $SITE_DIR;
    index index.php index.html;
    
    access_log /var/log/nginx/${domain}-access.log;
    error_log /var/log/nginx/${domain}-error.log;
    
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
    
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php${php_version}-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
    
    location ~ /\.ht {
        deny all;
    }
}
EOF
  
  ln -sf "/etc/nginx/sites-available/$domain.conf" "/etc/nginx/sites-enabled/"
  
  # Test Nginx
  if ! nginx -t &>/dev/null; then
    log_error "❌ Nginx config có lỗi"
    return 1
  fi
  
  systemctl reload nginx
  
  echo ""
  log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  log_info "✅ DEPLOY THÀNH CÔNG!"
  log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  log_info "🌐 Domain: http://$domain"
  log_info "📁 Site dir: $SITE_DIR"
  log_info "🐘 PHP: $php_version"
  log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# List deployed sites
list_deployed_sites() {
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📋 DANH SÁCH WEBSITES ĐÃ DEPLOY"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  if [ ! -d "/etc/nginx/sites-enabled" ]; then
    log_error "❌ Nginx chưa được cài đặt"
    return 1
  fi
  
  echo "Nginx sites:"
  for site in /etc/nginx/sites-enabled/*.conf; do
    if [ -f "$site" ]; then
      domain=$(basename "$site" .conf)
      root=$(grep "root " "$site" | head -1 | awk '{print $2}' | tr -d ';')
      echo "  - $domain → $root"
    fi
  done
  
  echo ""
  
  if command_exists pm2; then
    echo "PM2 NodeJS apps:"
    pm2 list
  fi
}

# Remove deployed site
remove_deployed_site() {
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🗑️  XÓA WEBSITE ĐÃ DEPLOY"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  # List sites
  list_deployed_sites
  echo ""
  
  if $use_gum; then
    domain=$(gum input --placeholder "Nhập domain cần xóa")
  else
    read -p "Nhập domain cần xóa: " domain
  fi
  
  if [ -z "$domain" ]; then
    log_error "❌ Domain không được để trống"
    return 1
  fi
  
  # Confirm
  if $use_gum; then
    confirm=$(gum choose "Xác nhận xóa" "Hủy")
    if [ "$confirm" != "Xác nhận xóa" ]; then
      log_info "❌ Đã hủy"
      return 0
    fi
  else
    read -p "Xác nhận xóa $domain? (y/n): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
      log_info "❌ Đã hủy"
      return 0
    fi
  fi
  
  # Remove Nginx config
  if [ -f "/etc/nginx/sites-enabled/$domain.conf" ]; then
    rm -f "/etc/nginx/sites-enabled/$domain.conf"
    rm -f "/etc/nginx/sites-available/$domain.conf"
    log_info "✅ Đã xóa Nginx config"
  fi
  
  # Remove PM2 app
  if command_exists pm2; then
    app_name="${domain//./-}"
    pm2 delete "$app_name" 2>/dev/null && log_info "✅ Đã xóa PM2 app"
  fi
  
  # Ask to remove files
  if $use_gum; then
    remove_files=$(gum choose "Giữ lại files" "Xóa luôn files")
  else
    read -p "Xóa luôn files trong /var/www/$domain? (y/n): " remove_files
  fi
  
  if [[ "$remove_files" =~ "Xóa luôn"  ]] || [[ "$remove_files" =~ ^[Yy]$ ]]; then
    rm -rf "/var/www/$domain"
    log_info "✅ Đã xóa files"
  fi
  
  # Reload Nginx
  systemctl reload nginx
  
  log_info "✅ Đã xóa website $domain"
}
