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

  # Tạo user mặc định
  filebrowser users add $USER $PASS --perm.admin

  # Tạo service systemd
  cat > /etc/systemd/system/filebrowser.service <<EOF
[Unit]
Description=File Browser
After=network.target

[Service]
User=root
WorkingDirectory=/opt/filebrowser
ExecStart=/usr/local/bin/filebrowser -p $PORT -r /var/www
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

