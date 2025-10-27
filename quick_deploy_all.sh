#!/bin/bash
# ========================================================
# 🚀 Quick Deploy All - Redis Queue System
# Version: 1.0
# ========================================================

set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 QUICK DEPLOY - REDIS QUEUE SYSTEM"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Please run as root (use sudo)"
    exit 1
fi

# Get main domain
read -p "👉 Enter your main domain (e.g., example.com): " MAIN_DOMAIN
if [ -z "$MAIN_DOMAIN" ]; then
    echo "❌ Domain required!"
    exit 1
fi

# Get subdomain
read -p "👉 Enter subdomain [tools]: " SUBDOMAIN
SUBDOMAIN=${SUBDOMAIN:-tools}

FULL_SUBDOMAIN="${SUBDOMAIN}.${MAIN_DOMAIN}"
MONITORING_DIR="/var/www/$FULL_SUBDOMAIN"
SERVER_IP=$(hostname -I | awk '{print $1}')

echo ""
echo "📋 Configuration:"
echo "   Subdomain: $FULL_SUBDOMAIN"
echo "   Dir: $MONITORING_DIR"
echo ""

# 1. Install PHP Redis Extension
echo "1️⃣ Installing PHP Redis extension..."
if ! php -m | grep -q redis; then
    apt-get update -qq
    apt-get install -y php-redis php8.2-redis php8.1-redis 2>/dev/null
    systemctl restart php8.2-fpm php8.1-fpm nginx 2>/dev/null
fi

# 2. Create monitoring directory
mkdir -p "$MONITORING_DIR"

# 3. Create all dashboard files
echo "2️⃣ Creating monitoring dashboards..."
chmod +x create_monitoring_dashboards.sh
./create_monitoring_dashboards.sh "$MONITORING_DIR" 2>/dev/null

# 4. Install Certbot if not installed
echo "3️⃣ Installing Certbot for SSL..."
if ! command -v certbot &> /dev/null; then
    apt-get install -y certbot python3-certbot-nginx 2>/dev/null
fi

# 5. Create Nginx config for subdomain (HTTP - will upgrade to HTTPS)
echo "4️⃣ Creating Nginx configuration..."
cat > "/etc/nginx/sites-available/$FULL_SUBDOMAIN.conf" << NGINXCFG
# HTTP server - redirect to HTTPS
server {
    listen 80;
    server_name $FULL_SUBDOMAIN;
    
    # Allow Let's Encrypt validation
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }
    
    # Temporary - serve content until SSL is configured
    root $MONITORING_DIR;
    index index.php index.html;
    
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
    
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.2-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
}
NGINXCFG

# Enable site
ln -sf "/etc/nginx/sites-available/$FULL_SUBDOMAIN.conf" /etc/nginx/sites-enabled/

# Test and reload Nginx
nginx -t && systemctl reload nginx

# 6. Get SSL certificate
echo "5️⃣ Requesting SSL certificate..."
if [ -d "/etc/letsencrypt/live/$FULL_SUBDOMAIN" ]; then
    echo "✅ SSL certificate already exists for $FULL_SUBDOMAIN"
else
    certbot --nginx -d $FULL_SUBDOMAIN --non-interactive --agree-tos --redirect 2>/dev/null || {
        echo "⚠️  SSL setup failed, continuing without HTTPS..."
        echo "   You can manually run: certbot --nginx -d $FULL_SUBDOMAIN"
    }
fi

# 7. Setup queue worker
echo "7️⃣ Setting up queue worker..."
PHP_PATH=$(which php)
WEB_ROOT="/var/www/html"

if [ ! -f "/etc/systemd/system/queue-worker.service" ]; then
    cat > /etc/systemd/system/queue-worker.service << EOFSERVICE
[Unit]
Description=VINAInbox Queue Worker
After=network.target redis.service

[Service]
Type=simple
User=www-data
WorkingDirectory=$WEB_ROOT
ExecStart=$PHP_PATH $WEB_ROOT/index.php Process_status_queue
Restart=always
RestartSec=10
StandardOutput=append:/var/log/queue_worker.log
StandardError=append:/var/log/queue_worker_error.log

[Install]
WantedBy=multi-user.target
EOFSERVICE

    systemctl daemon-reload
    systemctl enable queue-worker
    systemctl start queue-worker
fi

# 8. Set permissions
chown -R www-data:www-data "$MONITORING_DIR"
chmod -R 755 "$MONITORING_DIR"

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ DEPLOYMENT COMPLETE!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🌐 Access URL:"
echo "   https://$FULL_SUBDOMAIN"
echo "   (HTTP will auto-redirect to HTTPS)"
echo ""
echo "🔐 Default Password: CHANGE_THIS_PASSWORD_123"
echo "⚠️  CHANGE PASSWORD in $MONITORING_DIR/index.php"
echo ""
echo "📊 Available Tools:"
echo "   • Queue Monitor - View & flush queue"
echo "   • Cronjob Manager - Manage cronjobs"
echo "   • System Monitor - System stats"
echo "   • Redis Dashboard - Redis info"
echo "   • Worker Control - Start/stop worker"
echo "   • Database Stats - DB tables & sizes"
echo ""
echo "🔧 Management:"
echo "   systemctl status queue-worker"
echo "   tail -f /var/log/queue_worker.log"
echo "   redis-cli LLEN customer_status_queue"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

