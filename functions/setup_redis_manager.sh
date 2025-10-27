#!/bin/bash
# ========================================================
# 🔍 setup_redis_manager.sh - Setup Redis Monitoring & Cronjob Manager
# Version: 1.0
# Tools: RedisInsight (Official Redis UI)
# ========================================================

install_redisinsight() {
  log_info "Đang cài đặt RedisInsight (Official Redis UI)..."
  
  # Install Node.js if not exists
  if ! command_exists node; then
    log_info "Cài đặt Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt-get install -y nodejs
  fi
  
  # Install RedisInsight via npm
  npm install -g redisinsight-server
  
  # Create systemd service
  cat > /etc/systemd/system/redisinsight.service << 'EOF'
[Unit]
Description=RedisInsight Server
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/redisinsight-server --host 0.0.0.0 --port 8001
Restart=always

[Install]
WantedBy=multi-user.target
EOF
  
  systemctl daemon-reload
  systemctl enable redisinsight
  systemctl start redisinsight
  
  log_info "✅ RedisInsight đã được cài đặt"
  log_info "🌐 Access: http://YOUR_IP:8001"
}

# Simplified cronjob management via simple PHP page
setup_cronman() {
  log_info "Đang setup Cronjob Manager UI..."
  
  mkdir -p /var/www/html/admin
  
  # Create secure cronjob manager
  cat > /var/www/html/admin/cron.php << 'CRONPHP'
<?php
// Simple password protection
session_start();
$password = 'CHANGE_THIS_PASSWORD_123';

if (!isset($_SESSION['authenticated'])) {
    if (isset($_POST['pass']) && $_POST['pass'] === $password) {
        $_SESSION['authenticated'] = true;
    } else {
        ?>
        <form method="post">
            <input type="password" name="pass" placeholder="Password" required>
            <button>Login</button>
        </form>
        <?php
        exit;
    }
}

// Actions
if (isset($_GET['action'])) {
    switch($_GET['action']) {
        case 'list':
            header('Content-Type: text/plain');
            passthru('crontab -l 2>/dev/null');
            exit;
        
        case 'save':
            $cron = $_POST['cron'] ?? '';
            file_put_contents('/tmp/crontab.txt', $cron);
            system('crontab /tmp/crontab.txt');
            echo 'Saved! <a href="?">Back</a>';
            exit;
            
        case 'test':
            echo '<pre>' . shell_exec('crontab -l 2>/dev/null') . '</pre>';
            exit;
    }
}

$crons = shell_exec('crontab -l 2>/dev/null');
?>
<!DOCTYPE html>
<html>
<head>
    <title>Cronjob Manager</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; padding: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { margin-bottom: 20px; color: #333; }
        textarea { width: 100%; height: 400px; padding: 15px; font-family: 'Courier New', monospace; font-size: 13px; border: 1px solid #ddd; border-radius: 4px; }
        button { background: #007bff; color: white; border: none; padding: 12px 30px; border-radius: 4px; cursor: pointer; font-size: 14px; }
        button:hover { background: #0056b3; }
        .info { background: #e7f3ff; padding: 15px; border-radius: 4px; margin-bottom: 20px; border-left: 4px solid #007bff; }
        .example { background: #f8f9fa; padding: 10px; margin-top: 10px; border-radius: 4px; font-family: monospace; font-size: 12px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>📅 Cronjob Manager</h1>
        <div class="info">
            <strong>💡 Format:</strong> Minute Hour Day Month Weekday Command<br>
            <div class="example">
                * * * * * php /path/to/script.php  ← Every minute<br>
                0 * * * * php index.php Process_status_queue  ← Every hour<br>
                0 0 * * * /bin/bash /path/to/backup.sh  ← Daily at midnight<br>
            </div>
        </div>
        <form method="post" action="?action=save">
            <textarea name="cron" placeholder="# Add your cronjobs here..."><?= htmlspecialchars($crons) ?></textarea>
            <br><br>
            <button>💾 Save Cronjobs</button>
            <a href="?action=list" target="_blank"><button type="button">📋 View Raw</button></a>
            <a href="?action=test" target="_blank"><button type="button">🔍 Test</button></a>
        </form>
    </div>
</body>
</html>
CRONPHP
  
  chmod 644 /var/www/html/admin/cron.php
  
  log_info "✅ Cronjob Manager UI đã được setup"
  log_info "🌐 Access: http://YOUR_DOMAIN/admin/cron.php"
  log_info "⚠️  ĐỔI PASSWORD trong file cron.php!"
}

# Quick monitoring dashboard
setup_monitoring_dashboard() {
  log_info "Đang tạo Monitoring Dashboard..."
  
  cat > /var/www/html/admin/monitor.php << 'MONITOR'
<?php
$redis_stats = @shell_exec('redis-cli info stats 2>/dev/null');
$memory_stats = @shell_exec('redis-cli info memory 2>/dev/null');
$cron_count = shell_exec('crontab -l 2>/dev/null | grep -v "^#" | wc -l');
?>
<!DOCTYPE html>
<html>
<head>
    <title>System Monitor</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: -apple-system, sans-serif; padding: 20px; background: #f5f5f5; }
        .container { max-width: 1400px; margin: 0 auto; }
        .card { background: white; padding: 20px; border-radius: 8px; margin-bottom: 20px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h2 { color: #333; margin-bottom: 15px; }
        pre { background: #f8f9fa; padding: 15px; border-radius: 4px; overflow-x: auto; }
        .stat { display: inline-block; margin: 10px 20px 10px 0; padding: 15px 25px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; border-radius: 8px; }
        .stat-value { font-size: 2em; font-weight: bold; }
        .stat-label { font-size: 0.9em; opacity: 0.9; }
    </style>
    <script>
        setTimeout(() => location.reload(), 30000); // Auto refresh every 30s
    </script>
</head>
<body>
    <div class="container">
        <div class="card">
            <h2>📊 Quick Stats</h2>
            <div class="stat">
                <div class="stat-value"><?= $cron_count ?></div>
                <div class="stat-label">Active Cronjobs</div>
            </div>
        </div>
        
        <div class="card">
            <h2>🔴 Redis Stats</h2>
            <pre><?= htmlspecialchars($redis_stats ?: 'Redis not available') ?></pre>
        </div>
        
        <div class="card">
            <h2>💾 Memory Stats</h2>
            <pre><?= htmlspecialchars($memory_stats ?: 'Redis not available') ?></pre>
        </div>
    </div>
</body>
</html>
MONITOR
  
  chmod 644 /var/www/html/admin/monitor.php
  
  log_info "✅ Monitoring Dashboard đã được setup"
  log_info "🌐 Access: http://YOUR_DOMAIN/admin/monitor.php"
}

# Main function
if [ "$1" == "install" ]; then
  install_redisinsight
  setup_cronman
  setup_monitoring_dashboard
fi

