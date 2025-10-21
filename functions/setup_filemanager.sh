#!/bin/bash
# ========================================================
# 📂 setup_filemanager.sh - Cài FileBrowser (UI quản lý file)
# ========================================================

install_filemanager() {
  local PORT=${CONFIG_filemanager_port:-8080}
  local USER=${CONFIG_filemanager_username:-admin}
  # Generate 16-char password (FileBrowser requires min 12 chars)
  local PASS=$(random_password 16)

  log_info "Đang cài FileBrowser..."

  # Tạo thư mục chứa filebrowser data
  mkdir -p /etc/filebrowser
  mkdir -p /var/www

  # Tải và cài đặt FileBrowser (binary vào /usr/local/bin)
  curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash &>/dev/null

  # Kiểm tra file binary
  if ! command_exists filebrowser; then
    log_error "❌ FileBrowser binary không tồn tại. Cài đặt thất bại."
    return 1
  fi
  
  # Initialize filebrowser database
  mkdir -p /etc/filebrowser
  cd /etc/filebrowser
  
  # Init config database
  filebrowser config init --database /etc/filebrowser/filebrowser.db
  
  # Configure filebrowser (min password length is hardcoded to 12)
  filebrowser config set --address 0.0.0.0 --port $PORT --database /etc/filebrowser/filebrowser.db
  filebrowser config set --root /var/www --database /etc/filebrowser/filebrowser.db
  filebrowser config set --log /var/log/filebrowser.log --database /etc/filebrowser/filebrowser.db

  # Tạo user mặc định (password must be 12+ chars)
  filebrowser users add $USER $PASS --perm.admin --database /etc/filebrowser/filebrowser.db

  # Set ownership for filebrowser directory
  chown -R www-data:www-data /etc/filebrowser
  chown -R www-data:www-data /var/www
  
  # Tạo service systemd (run as www-data)
  cat > /etc/systemd/system/filebrowser.service <<EOF
[Unit]
Description=File Browser
After=network.target

[Service]
User=www-data
Group=www-data
WorkingDirectory=/etc/filebrowser
ExecStart=/usr/local/bin/filebrowser --database /etc/filebrowser/filebrowser.db
Restart=always
# Ensure proper permissions for uploads
UMask=0022

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable filebrowser &>/dev/null
  systemctl start filebrowser

  echo "filebrowser_user=$USER" >> "$BASE_DIR/logs/install.log"
  echo "filebrowser_pass=$PASS" >> "$BASE_DIR/logs/install.log"

  log_info "✅ FileBrowser chạy tại: http://$(hostname -I | awk '{print $1}'):$PORT"
  log_info "   User: $USER | Pass: $PASS"
}

# Reconfigure existing FileBrowser to listen on 0.0.0.0
reconfigure_filemanager() {
  log_info "Reconfiguring FileBrowser..."
  
  # Stop service first
  systemctl stop filebrowser 2>/dev/null
  sleep 2  # Wait for process to fully stop
  
  # Create database directory
  mkdir -p /etc/filebrowser
  
  # Check if old database exists
  if [ -f "/opt/filebrowser/filebrowser.db" ] && [ ! -f "/etc/filebrowser/filebrowser.db" ]; then
    log_info "Migrating old database..."
    cp /opt/filebrowser/filebrowser.db /etc/filebrowser/filebrowser.db
    chmod 644 /etc/filebrowser/filebrowser.db
  fi
  
  # Initialize if not exists
  if [ ! -f "/etc/filebrowser/filebrowser.db" ]; then
    cd /etc/filebrowser
    filebrowser config init --database /etc/filebrowser/filebrowser.db
    
    # Add default user (password must be 12+ chars)
    local USER=${CONFIG_filemanager_username:-admin}
    local PASS=${CONFIG_filemanager_password:-$(random_password 16)}
    filebrowser users add $USER $PASS --perm.admin --database /etc/filebrowser/filebrowser.db
    
    echo "filebrowser_user=$USER" >> "$BASE_DIR/logs/install.log"
    echo "filebrowser_pass=$PASS" >> "$BASE_DIR/logs/install.log"
    
    log_info "✅ Created user: $USER | Pass: $PASS"
  fi
  
  # Configure to listen on 0.0.0.0
  local PORT=${CONFIG_filemanager_port:-8080}
  cd /etc/filebrowser
  filebrowser config set --address 0.0.0.0 --port $PORT --database /etc/filebrowser/filebrowser.db
  filebrowser config set --root /var/www --database /etc/filebrowser/filebrowser.db
  
  # Set ownership
  chown -R www-data:www-data /etc/filebrowser
  
  # Update systemd service (run as www-data)
  cat > /etc/systemd/system/filebrowser.service <<EOF
[Unit]
Description=File Browser
After=network.target

[Service]
User=www-data
Group=www-data
WorkingDirectory=/etc/filebrowser
ExecStart=/usr/local/bin/filebrowser --database /etc/filebrowser/filebrowser.db
Restart=always
# Ensure proper permissions for uploads
UMask=0022

[Install]
WantedBy=multi-user.target
EOF
  
  # Reload and restart
  systemctl daemon-reload
  systemctl enable filebrowser 2>/dev/null
  systemctl start filebrowser
  
  # Wait for service to start
  sleep 2
  
  # Verify
  if netstat -tlnp 2>/dev/null | grep -q "0.0.0.0:$PORT"; then
    log_info "✅ FileBrowser reconfigured: http://$(hostname -I | awk '{print $1}'):$PORT"
    log_info "   Login info in: $BASE_DIR/logs/install.log"
  else
    log_error "❌ FileBrowser failed to start on 0.0.0.0:$PORT"
    journalctl -u filebrowser -n 10
  fi
}

# Fix FileBrowser to run as www-data (fix permission issues)
fix_filemanager_user() {
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🔧 FIX FILEBROWSER PERMISSIONS"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  if ! command_exists filebrowser; then
    log_error "❌ FileBrowser chưa được cài đặt"
    return 1
  fi
  
  # Check current user
  local current_user=$(systemctl show -p User filebrowser.service | cut -d= -f2)
  echo "📊 User hiện tại: ${current_user:-root}"
  
  if [ "$current_user" = "www-data" ]; then
    log_info "✅ FileBrowser đã chạy với user www-data"
    return 0
  fi
  
  log_info "🔄 Đang chuyển FileBrowser sang user www-data..."
  
  # Stop service
  systemctl stop filebrowser
  sleep 2
  
  # Set ownership
  log_info "📁 Đang fix ownership..."
  chown -R www-data:www-data /etc/filebrowser
  
  # Fix /var/www ownership
  if [ -d "/var/www" ]; then
    log_info "📁 Đang fix /var/www ownership..."
    chown -R www-data:www-data /var/www
    
    # Set proper permissions
    find /var/www -type d -exec chmod 755 {} \;
    find /var/www -type f -exec chmod 644 {} \;
    
    # Writable directories for Laravel/CodeIgniter
    for site_dir in /var/www/*/; do
      if [ -d "$site_dir" ]; then
        for wdir in storage writable bootstrap/cache uploads cache; do
          if [ -d "$site_dir/$wdir" ]; then
            chmod -R 775 "$site_dir/$wdir"
          fi
        done
      fi
    done
  fi
  
  # Update systemd service
  local PORT=$(grep -oP 'port \K[0-9]+' /etc/systemd/system/filebrowser.service 2>/dev/null || echo "8080")
  
  cat > /etc/systemd/system/filebrowser.service <<EOF
[Unit]
Description=File Browser
After=network.target

[Service]
User=www-data
Group=www-data
WorkingDirectory=/etc/filebrowser
ExecStart=/usr/local/bin/filebrowser --database /etc/filebrowser/filebrowser.db
Restart=always
# Ensure proper permissions for uploads
UMask=0022

[Install]
WantedBy=multi-user.target
EOF
  
  # Reload and restart
  systemctl daemon-reload
  systemctl start filebrowser
  sleep 2
  
  # Verify
  if systemctl is-active --quiet filebrowser; then
    local new_user=$(systemctl show -p User filebrowser.service | cut -d= -f2)
    echo ""
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "✅ FILEBROWSER ĐÃ ĐƯỢC FIX!"
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "👤 User mới: $new_user"
    log_info "📁 Owner: www-data:www-data"
    log_info "🔐 UMask: 0022 (file: 644, dir: 755)"
    log_info "💡 Files upload giờ sẽ có owner đúng!"
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  else
    log_error "❌ FileBrowser không thể start"
    journalctl -u filebrowser -n 20
    return 1
  fi
}

