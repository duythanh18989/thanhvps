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

# 4. Ensure index.php exists (main dashboard)
echo "2️⃣.1 Creating index.php dashboard..."
if [ ! -f "$MONITORING_DIR/index.php" ]; then
    cat > "$MONITORING_DIR/index.php" << 'INDEXMAIN'
<?php
// Simple auth
session_start();
$password = 'CHANGE_THIS_PASSWORD_123';

if (!isset($_SESSION['authenticated'])) {
    if (isset($_POST['pass']) && $_POST['pass'] === $password) {
        $_SESSION['authenticated'] = true;
    } else {
        ?>
        <!DOCTYPE html>
        <html>
        <head><title>Monitoring Tools Login</title>
        <style>
            body { font-family: sans-serif; padding: 50px; text-align: center; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; }
            .login-box { background: white; color: #333; padding: 40px; border-radius: 10px; display: inline-block; box-shadow: 0 10px 40px rgba(0,0,0,0.3); }
            input { padding: 12px 20px; width: 250px; margin: 10px 0; border: 1px solid #ddd; border-radius: 5px; font-size: 14px; }
            button { padding: 12px 40px; background: #667eea; color: white; border: none; border-radius: 5px; cursor: pointer; font-size: 16px; }
        </style>
        </head>
        <body>
            <h1>🔍 Monitoring Tools</h1>
            <div class="login-box">
                <form method="post">
                    <input type="password" name="pass" placeholder="Password" required autofocus>
                    <br><button>Login</button>
                </form>
            </div>
        </body>
        </html>
        <?php
        exit;
    }
}
?>
<!DOCTYPE html>
<html>
<head>
    <title>Monitoring Tools Dashboard</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: -apple-system, sans-serif; background: #f5f5f5; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; }
        .container { max-width: 1400px; margin: 0 auto; padding: 20px; }
        .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; margin-top: 30px; }
        .card { background: white; border-radius: 10px; padding: 25px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); transition: transform 0.2s; }
        .card:hover { transform: translateY(-5px); box-shadow: 0 4px 20px rgba(0,0,0,0.15); }
        .card h3 { color: #333; margin-bottom: 15px; }
        .card p { color: #666; margin-bottom: 20px; line-height: 1.6; }
        .btn { display: inline-block; padding: 12px 30px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; text-decoration: none; border-radius: 5px; font-weight: bold; transition: all 0.3s; }
        .btn:hover { opacity: 0.9; transform: scale(1.05); }
        .stat { background: #f8f9fa; padding: 15px; border-radius: 5px; margin: 10px 0; }
        .stat-label { font-size: 0.85em; color: #666; }
        .stat-value { font-size: 2em; font-weight: bold; color: #667eea; }
        .status { display: inline-block; padding: 4px 12px; border-radius: 20px; font-size: 0.85em; }
        .status-running { background: #d4edda; color: #155724; }
        .status-stopped { background: #f8d7da; color: #721c24; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🔍 Monitoring & Management Dashboard</h1>
        <p>VINAInbox Queue System</p>
    </div>
    <div class="container">
        <div style="background: white; padding: 20px; border-radius: 10px; margin-bottom: 20px; box-shadow: 0 2px 10px rgba(0,0,0,0.1);">
            <h3>📊 Quick Stats</h3>
            <div style="display: flex; gap: 20px; margin-top: 15px;">
                <?php
                try {
                    $redis = new Redis();
                    if (@$redis->connect('127.0.0.1', 6379)) {
                        $queue_length = $redis->lLen('customer_status_queue');
                        echo "<div class='stat'><div class='stat-label'>Queue Length</div><div class='stat-value'>$queue_length</div></div>";
                    }
                } catch (Exception $e) {}
                $worker_status = @shell_exec('systemctl is-active queue-worker 2>&1');
                $is_running = trim($worker_status) === 'active';
                $status_class = $is_running ? 'status-running' : 'status-stopped';
                $status_text = $is_running ? '🟢 Running' : '🔴 Stopped';
                echo "<div class='stat'><div class='stat-label'>Queue Worker</div><div class='stat-value'><span class='status $status_class'>$status_text</span></div></div>";
                ?>
            </div>
        </div>
        <div class="grid">
            <div class="card"><h3>📊 Queue Monitor</h3><p>Monitor Redis queue in real-time, view pending items, flush queue</p><a href="queue.php" class="btn">Open Dashboard →</a></div>
            <div class="card"><h3>📅 Cronjob Manager</h3><p>Manage cronjobs via web interface. Add, edit, delete jobs</p><a href="cron.php" class="btn">Manage Cronjobs →</a></div>
            <div class="card"><h3>⚙️ System Monitor</h3><p>Monitor system stats, Redis info, CPU, Memory usage</p><a href="monitor.php" class="btn">View Stats →</a></div>
            <div class="card"><h3>🔴 Redis Info</h3><p>View Redis server info, memory usage, connections</p><a href="redis.php" class="btn">Redis Dashboard →</a></div>
            <div class="card"><h3>🎛️ Worker Control</h3><p>Start/Stop/Restart queue worker, view logs</p><a href="worker.php" class="btn">Control Panel →</a></div>
            <div class="card"><h3>💾 Database Stats</h3><p>View database statistics, table info, slow queries</p><a href="db.php" class="btn">DB Dashboard →</a></div>
        </div>
    </div>
</body>
</html>
INDEXMAIN
fi

# 5. Fix permissions for ALL PHP files
echo "2️⃣.2 Fixing permissions..."
find "$MONITORING_DIR" -type d -exec chmod 755 {} \;
find "$MONITORING_DIR" -type f -name "*.php" -exec chmod 644 {} \;
chown -R www-data:www-data "$MONITORING_DIR"

# 6. Install Certbot if not installed
echo "3️⃣ Installing Certbot for SSL..."
if ! command -v certbot &> /dev/null; then
    apt-get install -y certbot python3-certbot-nginx 2>/dev/null
fi

# 7. Create Nginx config for subdomain (HTTP - will upgrade to HTTPS)
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

# 8. Get SSL certificate
echo "5️⃣ Requesting SSL certificate..."
if [ -d "/etc/letsencrypt/live/$FULL_SUBDOMAIN" ]; then
    echo "✅ SSL certificate already exists for $FULL_SUBDOMAIN"
else
    certbot --nginx -d $FULL_SUBDOMAIN --non-interactive --agree-tos --redirect 2>/dev/null || {
        echo "⚠️  SSL setup failed, continuing without HTTPS..."
        echo "   You can manually run: certbot --nginx -d $FULL_SUBDOMAIN"
    }
fi

# 9. Setup queue worker
echo "6️⃣ Setting up queue worker..."
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

# 10. Reload services
echo "7️⃣ Restarting services..."
systemctl reload php8.2-fpm nginx

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

