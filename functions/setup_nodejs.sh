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

# Manage PM2 apps
manage_pm2_apps() {
  if ! command_exists pm2; then
    log_error "❌ PM2 chưa được cài đặt"
    return 1
  fi
  
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🔧 QUẢN LÝ PM2 APPS"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  pm2 list
  echo ""
  
  if $use_gum; then
    action=$(gum choose "Start app" "Stop app" "Restart app" "Delete app" "View logs" "Save & Startup" "Quay lai")
  else
    echo "Chọn hành động:"
    echo "1) Start app"
    echo "2) Stop app"
    echo "3) Restart app"
    echo "4) Delete app"
    echo "5) View logs"
    echo "6) Save & Startup"
    echo "7) Quay lai"
    read -p "Chọn [1]: " choice
    case "$choice" in
      1) action="Start app" ;;
      2) action="Stop app" ;;
      3) action="Restart app" ;;
      4) action="Delete app" ;;
      5) action="View logs" ;;
      6) action="Save & Startup" ;;
      *) action="Quay lai" ;;
    esac
  fi
  
  echo ""
  
  case "$action" in
    "Start app"|"Stop app"|"Restart app"|"Delete app"|"View logs")
      if $use_gum; then
        app_name=$(gum input --placeholder "Nhập tên app hoặc ID")
      else
        read -p "Nhập tên app hoặc ID: " app_name
      fi
      
      case "$action" in
        "Start app")
          pm2 start "$app_name"
          ;;
        "Stop app")
          pm2 stop "$app_name"
          ;;
        "Restart app")
          pm2 restart "$app_name"
          ;;
        "Delete app")
          pm2 delete "$app_name"
          ;;
        "View logs")
          pm2 logs "$app_name" --lines 50
          ;;
      esac
      ;;
    
    "Save & Startup")
      pm2 save
      log_info "✅ Đã lưu danh sách apps. Apps sẽ tự động start khi reboot."
      ;;
    
    *)
      return 0
      ;;
  esac
}

# Manage Node versions
manage_node_versions() {
  if ! command_exists nvm; then
    log_error "❌ NVM chưa được cài đặt"
    return 1
  fi
  
  # Load NVM
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📦 QUẢN LÝ NODE VERSIONS"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Versions đã cài:"
  nvm list
  echo ""
  
  if $use_gum; then
    action=$(gum choose "Cài version mới" "Xóa version" "Đổi default version" "Quay lai")
  else
    echo "Chọn hành động:"
    echo "1) Cài version mới"
    echo "2) Xóa version"
    echo "3) Đổi default version"
    echo "4) Quay lai"
    read -p "Chọn [1]: " choice
    case "$choice" in
      1) action="Cài version mới" ;;
      2) action="Xóa version" ;;
      3) action="Đổi default version" ;;
      *) action="Quay lai" ;;
    esac
  fi
  
  echo ""
  
  case "$action" in
    "Cài version mới")
      if $use_gum; then
        version=$(gum input --placeholder "Nhập version (vd: 18, 20, 22, lts)")
      else
        read -p "Nhập version (18/20/22/lts): " version
      fi
      
      log_info "🔄 Đang cài Node.js ${version}..."
      nvm install "$version"
      log_info "✅ Đã cài Node.js ${version}"
      ;;
    
    "Xóa version")
      if $use_gum; then
        version=$(gum input --placeholder "Nhập version cần xóa")
      else
        read -p "Nhập version cần xóa: " version
      fi
      
      nvm uninstall "$version"
      log_info "✅ Đã xóa Node.js ${version}"
      ;;
    
    "Đổi default version")
      if $use_gum; then
        version=$(gum input --placeholder "Nhập version làm default")
      else
        read -p "Nhập version làm default: " version
      fi
      
      nvm alias default "$version"
      nvm use default
      log_info "✅ Default version: $(node -v)"
      ;;
    
    *)
      return 0
      ;;
  esac
}
