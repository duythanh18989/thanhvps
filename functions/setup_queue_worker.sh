#!/bin/bash
# ========================================================
# ⚙️ setup_queue_worker.sh - Setup Background Queue Worker
# Version: 1.0
# For: Redis customer status update queue
# ========================================================

setup_queue_cronjob() {
  log_info "Đang setup queue worker cronjob..."
  
  local web_root="/var/www/html" # Thay đổi theo config của bạn
  local php_path="/usr/bin/php"
  
  # Add cronjob to process queue every 30 seconds
  local cron_entry="*/30 * * * * $php_path $web_root/index.php Process_status_queue >> /var/log/queue_worker.log 2>&1"
  
  # Check if cronjob already exists
  if crontab -l 2>/dev/null | grep -q "Process_status_queue"; then
    log_info "Queue worker cronjob đã tồn tại"
    return 0
  fi
  
  # Add to crontab
  (crontab -l 2>/dev/null; echo "$cron_entry") | crontab -
  
  log_info "✅ Queue worker cronjob đã được thêm"
  log_info "📋 Running every 30 seconds"
}

# Setup systemd service (better than cron)
setup_queue_service() {
  log_info "Đang setup queue worker as systemd service..."
  
  local web_root="/var/www/html"
  local php_path="/usr/bin/php"
  
  cat > /etc/systemd/system/queue-worker.service << EOF
[Unit]
Description=Customer Status Queue Worker
After=network.target redis.service

[Service]
Type=simple
User=www-data
WorkingDirectory=$web_root
ExecStart=$php_path $web_root/index.php Process_status_queue
Restart=always
RestartSec=10
StandardOutput=append:/var/log/queue_worker.log
StandardError=append:/var/log/queue_worker_error.log

[Install]
WantedBy=multi-user.target
EOF
  
  systemctl daemon-reload
  systemctl enable queue-worker
  systemctl start queue-worker
  
  log_info "✅ Queue worker service đã được setup"
  log_info "📝 Status: systemctl status queue-worker"
  log_info "📝 Logs: tail -f /var/log/queue_worker.log"
}

# Create queue manager dashboard
create_queue_dashboard() {
  log_info "Đang tạo Queue Management Dashboard..."
  
  cat > /var/www/html/admin/queue.php << 'EOF'
<?php
// Queue Management Dashboard
$redis = @new Redis();
$connected = @$redis->connect('127.0.0.1', 6379);

if (!$connected) {
    die("Redis không khả dụng");
}

$queue_length = $redis->lLen('customer_status_queue');
$queue_stats = $redis->info('stats');

// Get recent queue items (last 10)
$recent_items = [];
for ($i = 0; $i < min(10, $queue_length); $i++) {
    $item = $redis->lIndex('customer_status_queue', $i);
    if ($item) {
        $recent_items[] = json_decode($item, true);
    }
}
?>
<!DOCTYPE html>
<html>
<head>
    <title>Queue Monitor</title>
    <meta http-equiv="refresh" content="5">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: -apple-system, sans-serif; padding: 20px; background: #f5f5f5; }
        .container { max-width: 1400px; margin: 0 auto; }
        .card { background: white; padding: 20px; border-radius: 8px; margin-bottom: 20px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #333; margin-bottom: 10px; }
        .stat { display: inline-block; margin: 10px 20px 10px 0; padding: 20px 30px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; border-radius: 8px; }
        .stat-value { font-size: 3em; font-weight: bold; }
        .stat-label { font-size: 0.9em; opacity: 0.9; margin-top: 5px; }
        table { width: 100%; border-collapse: collapse; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background: #f8f9fa; font-weight: 600; }
        .badge { padding: 4px 8px; border-radius: 4px; font-size: 0.85em; }
        .badge-success { background: #28a745; color: white; }
        .badge-failed { background: #dc3545; color: white; }
        .actions { margin-top: 20px; }
        .btn { padding: 10px 20px; border: none; border-radius: 4px; cursor: pointer; margin-right: 10px; }
        .btn-primary { background: #007bff; color: white; }
        .btn-danger { background: #dc3545; color: white; }
    </style>
</head>
<body>
    <div class="container">
        <div class="card">
            <h1>📊 Queue Monitor</h1>
            <div class="stat">
                <div class="stat-value"><?= $queue_length ?></div>
                <div class="stat-label">Pending Updates</div>
            </div>
            <div class="stat" style="background: linear-gradient(135deg, #28a745 0%, #20c997 100%);">
                <div class="stat-value"><?= $queue_length > 0 ? '⚠️' : '✅' ?></div>
                <div class="stat-label"><?= $queue_length > 0 ? 'Active' : 'Clean' ?></div>
            </div>
        </div>
        
        <div class="card">
            <h2>📋 Recent Queue Items</h2>
            <table>
                <thead>
                    <tr>
                        <th>Time</th>
                        <th>Page ID</th>
                        <th>UID</th>
                        <th>Status</th>
                        <th>Priority</th>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach ($recent_items as $item): ?>
                    <tr>
                        <td><?= htmlspecialchars($item['timestamp'] ?? 'N/A') ?></td>
                        <td><?= htmlspecialchars($item['fb_page_id'] ?? 'N/A') ?></td>
                        <td><?= htmlspecialchars($item['fb_uid'] ?? 'N/A') ?></td>
                        <td><span class="badge badge-<?= ($item['send_status'] ?? '') === 'success' ? 'success' : 'failed' ?>"><?= htmlspecialchars($item['send_status'] ?? 'N/A') ?></span></td>
                        <td><?= ($item['priority'] ?? 0) == 1 ? '🔴 High' : '🟢 Normal' ?></td>
                    </tr>
                    <?php endforeach; ?>
                    <?php if (empty($recent_items)): ?>
                    <tr><td colspan="5" style="text-align: center; color: #999;">Queue is empty</td></tr>
                    <?php endif; ?>
                </tbody>
            </table>
        </div>
        
        <div class="card">
            <div class="actions">
                <button class="btn btn-primary" onclick="location.reload()">🔄 Refresh</button>
                <button class="btn btn-danger" onclick="if(confirm('Flush all items?')) location.href='?flush=1'">🗑️ Flush Queue</button>
            </div>
        </div>
    </div>
    
    <?php if (isset($_GET['flush'])): ?>
        <?php $redis->del('customer_status_queue'); ?>
        <script>alert('Queue flushed!'); location.href='?';</script>
    <?php endif; ?>
</body>
</html>
EOF
  
  chmod 644 /var/www/html/admin/queue.php
  
  log_info "✅ Queue Management Dashboard đã được tạo"
  log_info "🌐 Access: http://YOUR_DOMAIN/admin/queue.php"
}

# Main function
if [ "$1" == "install" ]; then
  setup_queue_service
  create_queue_dashboard
  log_info "✅ Queue worker đã được setup hoàn tất"
fi

