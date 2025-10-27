#!/bin/bash
# ========================================================
# 🔍 setup_monitoring_tools.sh - Setup Monitoring Subdomain
# Version: 1.0
# Tạo subdomain riêng cho Queue Monitor, Cronjob Manager
# ========================================================

# Setup monitoring subdomain
setup_monitoring_subdomain() {
  log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  log_info "🔍 SETUP MONITORING SUBDOMAIN"
  log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  
  # Get main domain
  if $use_gum; then
    main_domain=$(gum input --placeholder "Nhập main domain (vd: example.com)")
    subdomain=$(gum input --placeholder "Nhập subdomain (vd: monitor hoặc tools)" --value "monitor")
  else
    read -p "👉 Nhập main domain (vd: example.com): " main_domain
    read -p "👉 Nhập subdomain [monitor]: " subdomain
    subdomain=${subdomain:-monitor}
  fi
  
  if [ -z "$main_domain" ]; then
    log_error "❌ Domain không được để trống"
    return 1
  fi
  
  # Get server IP to suggest port-based alternative
  server_ip=$(hostname -I | awk '{print $1}')
  
  full_subdomain="${subdomain}.${main_domain}"
  
  log_info "🌐 Subdomain: $full_subdomain"
  log_info "🔒 Protocol: HTTPS (SSL via Let's Encrypt)"
  
  # Create monitoring directory (use subdomain folder)
  monitoring_dir="/var/www/$full_subdomain"
  mkdir -p "$monitoring_dir"
  
  # Create index page with all tools
  cat > "$monitoring_dir/index.php" << 'INDEXEOF'
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
        <!-- Quick Stats -->
        <div style="background: white; padding: 20px; border-radius: 10px; margin-bottom: 20px; box-shadow: 0 2px 10px rgba(0,0,0,0.1);">
            <h3>📊 Quick Stats</h3>
            <div style="display: flex; gap: 20px; margin-top: 15px;">
                <?php
                // Get queue length
                try {
                    $redis = new Redis();
                    if (@$redis->connect('127.0.0.1', 6379)) {
                        $queue_length = $redis->lLen('customer_status_queue');
                        echo "<div class='stat'><div class='stat-label'>Queue Length</div><div class='stat-value'>$queue_length</div></div>";
                    }
                } catch (Exception $e) {}
                
                // Check queue worker
                $worker_status = @shell_exec('systemctl is-active queue-worker 2>&1');
                $is_running = trim($worker_status) === 'active';
                $status_class = $is_running ? 'status-running' : 'status-stopped';
                $status_text = $is_running ? '🟢 Running' : '🔴 Stopped';
                echo "<div class='stat'><div class='stat-label'>Queue Worker</div><div class='stat-value'><span class='status $status_class'>$status_text</span></div></div>";
                ?>
            </div>
        </div>
        
        <!-- Tools Grid -->
        <div class="grid">
            <!-- Queue Monitor -->
            <div class="card">
                <h3>📊 Queue Monitor</h3>
                <p>Monitor Redis queue in real-time, view pending items, flush queue</p>
                <a href="queue.php" class="btn">Open Dashboard →</a>
            </div>
            
            <!-- Cronjob Manager -->
            <div class="card">
                <h3>📅 Cronjob Manager</h3>
                <p>Manage cronjobs via web interface. Add, edit, delete jobs</p>
                <a href="cron.php" class="btn">Manage Cronjobs →</a>
            </div>
            
            <!-- System Monitor -->
            <div class="card">
                <h3>⚙️ System Monitor</h3>
                <p>Monitor system stats, Redis info, CPU, Memory usage</p>
                <a href="monitor.php" class="btn">View Stats →</a>
            </div>
            
            <!-- Redis Info -->
            <div class="card">
                <h3>🔴 Redis Info</h3>
                <p>View Redis server info, memory usage, connections</p>
                <a href="redis.php" class="btn">Redis Dashboard →</a>
            </div>
            
            <!-- Queue Worker Control -->
            <div class="card">
                <h3>🎛️ Worker Control</h3>
                <p>Start/Stop/Restart queue worker, view logs</p>
                <a href="worker.php" class="btn">Control Panel →</a>
            </div>
            
            <!-- Database Stats -->
            <div class="card">
                <h3>💾 Database Stats</h3>
                <p>View database statistics, table info, slow queries</p>
                <a href="db.php" class="btn">DB Dashboard →</a>
            </div>
        </div>
    </div>
</body>
</html>
INDEXEOF

  # Move existing tools to monitoring directory
  mkdir -p "$monitoring_dir"
  
  # Copy/create individual tools
  [ -f "/var/www/html/admin/queue.php" ] && cp "/var/www/html/admin/queue.php" "$monitoring_dir/"
  [ -f "/var/www/html/admin/cron.php" ] && cp "/var/www/html/admin/cron.php" "$monitoring_dir/"
  [ -f "/var/www/html/admin/monitor.php" ] && cp "/var/www/html/admin/monitor.php" "$monitoring_dir/"
  
  # Set permissions
  chown -R www-data:www-data "$monitoring_dir"
  chmod -R 755 "$monitoring_dir"
  
  # Install Certbot if needed
  if ! command -v certbot &> /dev/null; then
    log_info "📦 Installing Certbot for SSL..."
    apt-get install -y certbot python3-certbot-nginx 2>/dev/null
  fi
  
  # Create Nginx config for subdomain
  log_info "🔧 Creating Nginx config for $full_subdomain..."
  
  cat > "/etc/nginx/sites-available/$full_subdomain.conf" << NGINXCONF
# HTTP - will be upgraded to HTTPS by Certbot
server {
    listen 80;
    server_name $full_subdomain;
    
    # Let's Encrypt validation
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }
    
    root $monitoring_dir;
    index index.php index.html;
    
    access_log /var/log/nginx/${subdomain}-access.log;
    error_log /var/log/nginx/${subdomain}-error.log;
    
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
    
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php${CONFIG_default_php:-8.2}-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
}
NGINXCONF

  # Enable site
  ln -sf "/etc/nginx/sites-available/$full_subdomain.conf" /etc/nginx/sites-enabled/
  
  # Test and reload Nginx
  if nginx -t &>/dev/null; then
    systemctl reload nginx
    log_info "✅ Nginx config created and reloaded"
  else
    log_error "❌ Nginx config test failed"
    return 1
  fi
  
  # Get SSL certificate
  log_info "🔒 Requesting SSL certificate..."
  if [ -d "/etc/letsencrypt/live/$full_subdomain" ]; then
    log_info "✅ SSL certificate already exists"
  else
    certbot --nginx -d $full_subdomain --non-interactive --agree-tos --redirect 2>/dev/null || {
      log_warn "⚠️  SSL setup failed, continuing without HTTPS..."
      log_info "   You can manually run: certbot --nginx -d $full_subdomain"
    }
  fi
  
  echo ""
  log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  log_info "✅ MONITORING TOOLS SETUP COMPLETE!"
  log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  log_info "🌐 HTTPS Access:"
  log_info "   https://$full_subdomain"
  log_info "   (HTTP auto-redirects to HTTPS)"
  log_info ""
  log_info "🔐 Password: CHANGE_THIS_PASSWORD_123"
  log_info "⚠️  ĐỔI PASSWORD trong $monitoring_dir/index.php!"
  log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

