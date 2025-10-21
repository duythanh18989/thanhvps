#!/bin/bash
# ========================================================
# 📂 setup_filemanager.sh - Cài FileBrowser (UI quản lý file)
# ========================================================

install_filemanager() {
  local PORT=${CONFIG_filemanager_port:-8080}
  local USER=${CONFIG_filemanager_username:-admin}
  local PASS=$(random_password 16)

  log_info "Đang cài FileBrowser..."

  # Tạo thư mục chứa filebrowser data
  mkdir -p /opt/filebrowser
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
  
  # Configure filebrowser
  filebrowser config set --address 0.0.0.0 --port $PORT --database /etc/filebrowser/filebrowser.db
  filebrowser config set --root /var/www --database /etc/filebrowser/filebrowser.db
  filebrowser config set --log /var/log/filebrowser.log --database /etc/filebrowser/filebrowser.db

  # Tạo user mặc định
  filebrowser users add $USER $PASS --perm.admin --database /etc/filebrowser/filebrowser.db

  # Tạo service systemd
  cat > /etc/systemd/system/filebrowser.service <<EOF
[Unit]
Description=File Browser
After=network.target

[Service]
User=root
WorkingDirectory=/etc/filebrowser
ExecStart=/usr/local/bin/filebrowser --database /etc/filebrowser/filebrowser.db
Restart=always

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
    
    # Add default user
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
  
  # Update systemd service
  cat > /etc/systemd/system/filebrowser.service <<EOF
[Unit]
Description=File Browser
After=network.target

[Service]
User=root
WorkingDirectory=/etc/filebrowser
ExecStart=/usr/local/bin/filebrowser --database /etc/filebrowser/filebrowser.db
Restart=always

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

