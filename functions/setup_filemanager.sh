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

