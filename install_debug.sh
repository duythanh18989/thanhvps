#!/bin/bash
# ========================================================
# 🧪 ThanhTV VPS Installer - Debug Version
# Simple version for testing/debugging
# ========================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧪 ThanhTV VPS Installer v2.0 (DEBUG MODE)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check root
if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run as root"
  exit 1
fi

# Set BASE_DIR
export BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
echo "✅ BASE_DIR: $BASE_DIR"

# Load utils
if [ -f "$BASE_DIR/functions/utils.sh" ]; then
  source "$BASE_DIR/functions/utils.sh"
  echo "✅ Loaded utils.sh"
else
  echo "❌ Cannot find utils.sh"
  exit 1
fi

# Load config
if [ -f "$BASE_DIR/config.yml" ]; then
  echo "✅ Found config.yml"
  log_info "Parsing config..."
  parse_yaml "$BASE_DIR/config.yml" "CONFIG_"
  log_info "✅ Config loaded"
  
  # Show some config
  echo "   - domain: $CONFIG_default_domain"
  echo "   - php: $CONFIG_default_php"
  echo "   - redis: $CONFIG_redis_enabled"
else
  echo "❌ Cannot find config.yml"
  exit 1
fi

# Check gum
echo ""
log_info "Checking gum..."
check_gum
echo ""

# Ask domain
read -p "Enter domain (default: $CONFIG_default_domain): " DOMAIN
DOMAIN=${DOMAIN:-$CONFIG_default_domain}
log_info "Will use domain: $DOMAIN"

# Generate MySQL password
MYSQL_PASS=$(random_password 16)
log_info "MySQL root password generated"

# Load modules
echo ""
log_info "Loading modules..."
for module in setup_nginx setup_php setup_mysql; do
  if [ -f "$BASE_DIR/functions/${module}.sh" ]; then
    source "$BASE_DIR/functions/${module}.sh"
    echo "  ✅ $module.sh"
  else
    echo "  ❌ $module.sh NOT FOUND"
  fi
done

echo ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "Ready to install. Press ENTER to continue or Ctrl+C to cancel"
read

# Install
echo ""
log_info "Starting installation..."

echo ""
log_info "[1/3] Installing Nginx..."
if install_nginx "$DOMAIN"; then
  log_info "✅ Nginx OK"
else
  log_error "❌ Nginx FAILED"
fi

echo ""
log_info "[2/3] Installing PHP..."
if install_php; then
  log_info "✅ PHP OK"
else
  log_error "❌ PHP FAILED"
fi

echo ""
log_info "[3/3] Installing MariaDB..."
if install_mysql "$MYSQL_PASS"; then
  log_info "✅ MariaDB OK"
else
  log_error "❌ MariaDB FAILED"
fi

echo ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "🎉 Installation complete!"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Domain: $DOMAIN"
echo "MySQL root: $MYSQL_PASS"
echo ""
log_info "Check services:"
echo "  systemctl status nginx"
echo "  systemctl status php8.2-fpm"
echo "  systemctl status mariadb"
