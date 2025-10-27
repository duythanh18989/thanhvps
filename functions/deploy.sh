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
  log_info "🔐 Cài đặt permissions..."
  chown -R www-data:www-data "$SITE_DIR"
  find "$SITE_DIR" -type d -exec chmod 755 {} \;
  find "$SITE_DIR" -type f -exec chmod 644 {} \;
  
  # Set writable directories for Laravel/CodeIgniter
  for wdir in storage writable bootstrap/cache uploads cache; do
    if [ -d "$SITE_DIR/$wdir" ]; then
      chmod -R 775 "$SITE_DIR/$wdir"
    fi
  done
  
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

# Deploy Redis Queue System
deploy_redis_queue_system() {
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📊 DEPLOY REDIS QUEUE SYSTEM"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  # Check if script exists
  if [ ! -f "$BASE_DIR/quick_deploy_all.sh" ]; then
    log_error "❌ quick_deploy_all.sh không tìm thấy!"
    echo "   Path: $BASE_DIR/quick_deploy_all.sh"
    return 1
  fi
  
  log_info "🚀 Bắt đầu deploy Redis Queue System..."
  echo ""
  
  # Run quick_deploy_all script
  bash "$BASE_DIR/quick_deploy_all.sh"
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

# Change PHP version for deployed site
change_site_php_version() {
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🐘 ĐỔI PHP VERSION CHO SITE"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  # List PHP sites (exclude phpmyadmin and non-PHP sites)
  echo "📋 Danh sách PHP sites:"
  if [ ! -d "/etc/nginx/sites-enabled" ]; then
    log_error "❌ Nginx chưa được cài đặt"
    return 1
  fi
  
  local php_sites=()
  for site in /etc/nginx/sites-enabled/*.conf; do
    if [ -f "$site" ] && grep -q "fastcgi_pass" "$site" 2>/dev/null; then
      domain=$(basename "$site" .conf)
      current_php=$(grep -oP 'php\K[0-9.]+' "$site" | head -1)
      echo "  - $domain (PHP ${current_php:-unknown})"
      php_sites+=("$domain")
    fi
  done
  
  if [ ${#php_sites[@]} -eq 0 ]; then
    log_error "❌ Không tìm thấy PHP site nào"
    return 1
  fi
  
  echo ""
  
  # Input domain
  if $use_gum; then
    domain=$(gum input --placeholder "Nhập domain cần đổi PHP version")
  else
    read -p "Nhập domain: " domain
  fi
  
  if [ -z "$domain" ]; then
    log_error "❌ Domain không được để trống"
    return 1
  fi
  
  # Check if site exists
  if [ ! -f "/etc/nginx/sites-available/$domain.conf" ]; then
    log_error "❌ Site $domain không tồn tại"
    return 1
  fi
  
  # Check if it's a PHP site
  if ! grep -q "fastcgi_pass" "/etc/nginx/sites-available/$domain.conf" 2>/dev/null; then
    log_error "❌ $domain không phải là PHP site"
    return 1
  fi
  
  # Get current PHP version
  current_php=$(grep -oP 'php\K[0-9.]+' "/etc/nginx/sites-available/$domain.conf" | head -1)
  
  echo "📊 PHP version hiện tại: ${current_php:-unknown}"
  echo ""
  
  # List available PHP versions
  echo "📦 PHP versions có sẵn:"
  local available_versions=()
  for ver in 7.4 8.1 8.2 8.3; do
    if systemctl list-unit-files | grep -q "php${ver}-fpm.service" 2>/dev/null; then
      echo "  ✅ PHP $ver"
      available_versions+=("$ver")
    else
      echo "  ❌ PHP $ver (chưa cài)"
    fi
  done
  
  if [ ${#available_versions[@]} -eq 0 ]; then
    log_error "❌ Không có PHP version nào được cài đặt"
    return 1
  fi
  
  echo ""
  
  # Select new version
  if $use_gum; then
    new_version=$(gum choose "${available_versions[@]}")
  else
    echo "Chọn PHP version mới:"
    for i in "${!available_versions[@]}"; do
      echo "$((i+1))) ${available_versions[$i]}"
    done
    read -p "Chọn [1]: " choice
    choice=${choice:-1}
    new_version="${available_versions[$((choice-1))]}"
  fi
  
  if [ -z "$new_version" ]; then
    log_error "❌ Vui lòng chọn PHP version"
    return 1
  fi
  
  if [ "$new_version" = "$current_php" ]; then
    log_warn "⚠️  PHP version đã là $new_version rồi!"
    return 0
  fi
  
  # Backup config
  cp "/etc/nginx/sites-available/$domain.conf" "/etc/nginx/sites-available/$domain.conf.bak"
  
  # Update Nginx config
  log_info "🔄 Đang cập nhật Nginx config..."
  
  # Replace PHP-FPM socket path
  sed -i "s|php[0-9.]*-fpm.sock|php${new_version}-fpm.sock|g" "/etc/nginx/sites-available/$domain.conf"
  
  # Test Nginx config
  if ! nginx -t &>/dev/null; then
    log_error "❌ Nginx config có lỗi, rollback..."
    mv "/etc/nginx/sites-available/$domain.conf.bak" "/etc/nginx/sites-available/$domain.conf"
    return 1
  fi
  
  # Reload Nginx
  systemctl reload nginx
  
  # Remove backup
  rm -f "/etc/nginx/sites-available/$domain.conf.bak"
  
  echo ""
  log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  log_info "✅ ĐÃ ĐỔI PHP VERSION THÀNH CÔNG!"
  log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  log_info "🌐 Site: $domain"
  log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  log_info "🐘 PHP cũ: ${current_php:-unknown}"
  log_info "🐘 PHP mới: $new_version"
  log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Fix permissions for website
fix_site_permissions() {
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🔐 SỬA PERMISSIONS CHO WEBSITE"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  # List sites
  if [ ! -d "/var/www" ]; then
    log_error "❌ Thư mục /var/www không tồn tại"
    return 1
  fi
  
  echo "📋 Danh sách websites trong /var/www:"
  local sites=()
  for dir in /var/www/*/; do
    if [ -d "$dir" ]; then
      site=$(basename "$dir")
      owner=$(stat -c '%U:%G' "$dir" 2>/dev/null || echo "unknown")
      echo "  - $site (owner: $owner)"
      sites+=("$site")
    fi
  done
  
  if [ ${#sites[@]} -eq 0 ]; then
    log_error "❌ Không tìm thấy website nào"
    return 1
  fi
  
  echo ""
  
  # Input domain
  if $use_gum; then
    domain=$(gum input --placeholder "Nhập domain cần fix permissions (hoặc 'all' để fix tất cả)")
  else
    read -p "Nhập domain (hoặc 'all' để fix tất cả): " domain
  fi
  
  if [ -z "$domain" ]; then
    log_error "❌ Domain không được để trống"
    return 1
  fi
  
  # Fix permissions function
  fix_perms_for_site() {
    local site_path=$1
    local site_name=$2
    
    log_info "🔧 Đang fix permissions cho: $site_name"
    
    # Set owner to www-data:www-data
    chown -R www-data:www-data "$site_path"
    
    # Set directory permissions to 755
    find "$site_path" -type d -exec chmod 755 {} \;
    
    # Set file permissions to 644
    find "$site_path" -type f -exec chmod 644 {} \;
    
    # Special permissions for writable directories (if exist)
    local writable_dirs=(
      "storage"
      "storage/logs"
      "storage/framework"
      "storage/framework/cache"
      "storage/framework/sessions"
      "storage/framework/views"
      "bootstrap/cache"
      "writable"
      "uploads"
      "cache"
      "tmp"
    )
    
    for wdir in "${writable_dirs[@]}"; do
      if [ -d "$site_path/$wdir" ]; then
        chmod -R 775 "$site_path/$wdir"
        log_info "  ✅ Đã set 775 cho: $wdir"
      fi
    done
    
    # Make shell scripts executable (if exist)
    find "$site_path" -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null
    
    log_info "✅ Hoàn thành: $site_name"
  }
  
  # Execute
  if [ "$domain" = "all" ]; then
    log_info "🔄 Đang fix permissions cho TẤT CẢ websites..."
    echo ""
    
    for site in "${sites[@]}"; do
      fix_perms_for_site "/var/www/$site" "$site"
      echo ""
    done
    
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "✅ ĐÃ FIX TẤT CẢ WEBSITES!"
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  else
    if [ ! -d "/var/www/$domain" ]; then
      log_error "❌ Website $domain không tồn tại"
      return 1
    fi
    
    fix_perms_for_site "/var/www/$domain" "$domain"
    
    echo ""
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "✅ ĐÃ FIX PERMISSIONS!"
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "🌐 Website: $domain"
    log_info "📁 Path: /var/www/$domain"
    log_info "👤 Owner: www-data:www-data"
    log_info "📋 Dirs: 755 | Files: 644 | Writable: 775"
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  fi
}

# Add alias/additional domain to existing site
add_site_alias() {
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🔗 THÊM ALIAS/DOMAIN PHỤ CHO SITE"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  if [ ! -d "/etc/nginx/sites-enabled" ]; then
    log_error "❌ Nginx chưa được cài đặt"
    return 1
  fi
  
  # List existing sites
  echo "📋 Danh sách sites hiện có:"
  local sites=()
  for site in /etc/nginx/sites-enabled/*.conf; do
    if [ -f "$site" ]; then
      domain=$(basename "$site" .conf)
      current_aliases=$(grep "server_name" "$site" | head -1 | sed 's/server_name//' | tr -d ';' | xargs)
      echo "  - $domain"
      echo "    Aliases: $current_aliases"
      sites+=("$domain")
    fi
  done
  
  if [ ${#sites[@]} -eq 0 ]; then
    log_error "❌ Không tìm thấy site nào"
    return 1
  fi
  
  echo ""
  
  # Input primary domain
  if $use_gum; then
    primary_domain=$(gum input --placeholder "Nhập domain chính (vd: example.com)")
  else
    read -p "Nhập domain chính: " primary_domain
  fi
  
  if [ -z "$primary_domain" ]; then
    log_error "❌ Domain không được để trống"
    return 1
  fi
  
  # Check if site exists
  if [ ! -f "/etc/nginx/sites-available/$primary_domain.conf" ]; then
    log_error "❌ Site $primary_domain không tồn tại"
    return 1
  fi
  
  # Show current aliases
  current_server_names=$(grep "server_name" "/etc/nginx/sites-available/$primary_domain.conf" | head -1 | sed 's/server_name//' | tr -d ';' | xargs)
  echo "📊 Server names hiện tại: $current_server_names"
  echo ""
  
  # Input new aliases
  if $use_gum; then
    new_aliases=$(gum input --placeholder "Nhập aliases mới (cách nhau bằng space, vd: www.example.com api.example.com)")
  else
    read -p "Nhập aliases mới (cách nhau bằng space): " new_aliases
  fi
  
  if [ -z "$new_aliases" ]; then
    log_error "❌ Aliases không được để trống"
    return 1
  fi
  
  # Backup config
  cp "/etc/nginx/sites-available/$primary_domain.conf" "/etc/nginx/sites-available/$primary_domain.conf.bak"
  
  # Update server_name directive
  log_info "🔄 Đang cập nhật Nginx config..."
  
  # Combine old and new aliases
  all_aliases="$current_server_names $new_aliases"
  
  # Replace server_name line
  sed -i "0,/server_name.*/ s/server_name.*/    server_name $all_aliases;/" "/etc/nginx/sites-available/$primary_domain.conf"
  
  # Test Nginx config
  if ! nginx -t &>/dev/null; then
    log_error "❌ Nginx config có lỗi, rollback..."
    mv "/etc/nginx/sites-available/$primary_domain.conf.bak" "/etc/nginx/sites-available/$primary_domain.conf"
    return 1
  fi
  
  # Reload Nginx
  systemctl reload nginx
  
  # Remove backup
  rm -f "/etc/nginx/sites-available/$primary_domain.conf.bak"
  
  echo ""
  log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  log_info "✅ ĐÃ THÊM ALIASES THÀNH CÔNG!"
  log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  log_info "🌐 Site chính: $primary_domain"
  log_info "🔗 Tất cả domains:"
  for alias in $all_aliases; do
    log_info "   - $alias"
  done
  log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  log_info "💡 Nhớ trỏ DNS của các aliases về IP server!"
}
