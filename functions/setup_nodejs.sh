#!/bin/bash
# ========================================================
# 🟢 setup_nodejs.sh - Cài đặt NodeJS qua NVM
# Version: 1.0
# ========================================================

install_nodejs() {
  log_info "Đang cài đặt NodeJS via NVM..."
  
  # Kiểm tra NVM đã cài chưa
  if [ -d "$HOME/.nvm" ]; then
    log_info "NVM đã được cài đặt"
  else
    log_info "Cài đặt NVM (Node Version Manager)..."
    
    # Download và cài NVM
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    
    # Load NVM
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    
    log_info "✅ NVM đã được cài đặt"
  fi
  
  # Load NVM nếu chưa có
  if ! command_exists nvm; then
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  fi
  
  # Lấy danh sách versions từ config
  if [ -n "$CONFIG_nodejs_versions" ]; then
    IFS=' ' read -ra NODE_VERSIONS <<< "$CONFIG_nodejs_versions"
  else
    NODE_VERSIONS=("18" "20")
  fi
  
  local default_version=${CONFIG_nodejs_default_version:-20}
  
  log_info "Cài đặt NodeJS versions: ${NODE_VERSIONS[*]}"
  
  # Cài từng version
  for ver in "${NODE_VERSIONS[@]}"; do
    log_info "Cài đặt Node.js ${ver}..."
    
    if ! nvm install "$ver" &>/dev/null; then
      log_error "Không thể cài Node.js ${ver}"
      continue
    fi
    
    log_info "✅ Node.js ${ver} đã được cài đặt"
  done
  
  # Set default version
  log_info "Đặt Node.js ${default_version} làm mặc định..."
  nvm alias default "$default_version" &>/dev/null
  nvm use default &>/dev/null
  
  # Cài PM2 global (process manager cho Node.js)
  log_info "Cài đặt PM2 (Process Manager)..."
  npm install -g pm2 &>/dev/null
  
  # Setup PM2 startup
  pm2 startup systemd -u root --hp /root &>/dev/null
  
  log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  log_info "🟢 NodeJS đã được cài đặt"
  log_info "📋 Node: $(node -v)"
  log_info "📦 NPM: $(npm -v)"
  log_info "🔧 PM2: $(pm2 -v)"
  log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  
  # Ghi log
  echo "$(date '+%Y-%m-%d %H:%M:%S') | INSTALL NODEJS | $(node -v)" >> "$BASE_DIR/logs/install.log"
  
  return 0
}

# Show NodeJS info
nodejs_info() {
  if ! command_exists node; then
    log_error "NodeJS chưa được cài đặt"
    return 1
  fi
  
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🟢 NODEJS INFO"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Node: $(node -v)"
  echo "NPM: $(npm -v)"
  
  if command_exists nvm; then
    echo ""
    echo "NVM versions installed:"
    nvm list
  fi
  
  if command_exists pm2; then
    echo ""
    echo "PM2 version: $(pm2 -v)"
    echo ""
    echo "PM2 processes:"
    pm2 list
  fi
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}
