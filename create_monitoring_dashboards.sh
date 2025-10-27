#!/bin/bash
# ========================================================
# 🎨 Create Complete Monitoring Dashboards
# Version: 1.0
# Usage: ./create_monitoring_dashboards.sh [MONITORING_DIR]
# ========================================================

# Get MONITORING_DIR from parameter or use default
MONITORING_DIR="${1:-/var/www/monitoring-tools}"
mkdir -p "$MONITORING_DIR"

echo "Creating monitoring dashboards in: $MONITORING_DIR"

# 1. Queue Monitor
cat > "$MONITORING_DIR/queue.php" << 'QUEUEPHP'
<?php
$redis = new Redis();
@$redis->connect('127.0.0.1', 6379);
$queue_length = $redis->lLen('customer_status_queue');

if (isset($_GET['flush'])) {
    $redis->del('customer_status_queue');
    echo "<script>alert('Flushed!'); location.href='?';</script>";
    exit;
}

// Get recent items
$items = [];
for ($i = 0; $i < min(20, $queue_length); $i++) {
    $item = $redis->lIndex('customer_status_queue', $i);
    if ($item) $items[] = json_decode($item, true);
}
?>
<!DOCTYPE html><html><head>
<title>Queue Monitor</title>
<meta http-equiv="refresh" content="5">
<style>
body{font-family:sans-serif;padding:20px;background:#f5f5f5}
.card{background:white;padding:20px;border-radius:8px;margin:20px 0;box-shadow:0 2px 10px rgba(0,0,0,0.1)}
.stat{display:inline-block;margin:10px;padding:20px;background:linear-gradient(135deg,#667eea 0%,#764ba2 100%);color:white;border-radius:8px}
.stat-value{font-size:2em;font-weight:bold}
table{width:100%;border-collapse:collapse}
th,td{padding:12px;text-align:left;border-bottom:1px solid #ddd}
.btn{padding:10px 20px;background:#dc3545;color:white;border:none;border-radius:4px;text-decoration:none;margin:5px}
</style>
</head>
<body>
<h1>📊 Queue Monitor</h1>
<div class="card">
<div class="stat"><div class="stat-value"><?=$queue_length?></div>Pending</div>
<a href="?flush=1" class="btn">🗑️ Flush</a>
</div>

<div class="card">
<h2>Recent Items</h2>
<table>
<thead><tr><th>Time</th><th>Page</th><th>UID</th><th>Status</th></tr></thead>
<tbody>
<?php foreach($items as $i): ?>
<tr>
<td><?=htmlspecialchars($i['timestamp']??'')?></td>
<td><?=htmlspecialchars($i['fb_page_id']??'')?></td>
<td><?=htmlspecialchars($i['fb_uid']??'')?></td>
<td><span style="padding:4px 8px;background:<?=$i['send_status']=='success'?'#28a745':'#dc3545'?>;color:white;border-radius:4px"><?=htmlspecialchars($i['send_status']??'')?></span></td>
</tr>
<?php endforeach; ?>
</tbody>
</table>
</div>
</body></html>
QUEUEPHP

# 2. Cronjob Manager
cat > "$MONITORING_DIR/cron.php" << 'CRONPHP'
<?php
session_start();
$password = 'CHANGE_THIS_PASSWORD_123';

if (!isset($_SESSION['authenticated'])) {
    if (isset($_POST['pass']) && $_POST['pass'] === $password) {
        $_SESSION['authenticated'] = true;
    } else {
        ?>
        <form method="post"><input name="pass" type="password" placeholder="Password" required><button>Login</button></form>
        <?php exit;
    }
}

if (isset($_GET['action'])) {
    switch($_GET['action']) {
        case 'save':
            $cron = $_POST['cron'] ?? '';
            file_put_contents('/tmp/crontab.txt', $cron);
            shell_exec('crontab /tmp/crontab.txt');
            echo 'Saved! <a href="?">Back</a>';
            exit;
        case 'list':
            header('Content-Type: text/plain');
            passthru('crontab -l 2>/dev/null');
            exit;
    }
}

$crons = shell_exec('crontab -l 2>/dev/null');
?>
<!DOCTYPE html><html><head><title>Cron Manager</title>
<style>
body{font-family:sans-serif;padding:20px;background:#f5f5f5}
.container{max-width:1200px;margin:0 auto;background:white;padding:30px;border-radius:8px}
textarea{width:100%;height:400px;padding:15px;font-family:monospace;font-size:13px;border:1px solid #ddd}
button{background:#007bff;color:white;border:none;padding:12px 30px;border-radius:4px;cursor:pointer}
</style>
</head>
<body>
<div class="container">
<h1>📅 Cronjob Manager</h1>
<form method="post" action="?action=save">
<textarea name="cron"><?=htmlspecialchars($crons)?></textarea><br><br>
<button>💾 Save</button>
<a href="?action=list" target="_blank"><button type="button">📋 View</button></a>
</form>
</div>
</body></html>
CRONPHP

# 3. System Monitor
cat > "$MONITORING_DIR/monitor.php" << 'MONITORPHP'
<!DOCTYPE html><html><head><title>System Monitor</title>
<meta http-equiv="refresh" content="10">
<style>
body{font-family:sans-serif;padding:20px;background:#f5f5f5}
.card{background:white;padding:20px;border-radius:8px;margin:20px 0}
pre{background:#f8f9fa;padding:15px;border-radius:4px;overflow-x:auto}
.stat{display:inline-block;margin:10px 20px 10px 0;padding:20px 30px;background:linear-gradient(135deg,#667eea 0%,#764ba2 100%);color:white;border-radius:8px}
.stat-value{font-size:2em;font-weight:bold}
</style>
</head>
<body>
<h1>⚙️ System Monitor</h1>

<div class="card">
<h2>📊 Stats</h2>
<?php
$cron_count = shell_exec('crontab -l 2>/dev/null | grep -v "^#" | wc -l');
$worker_status = trim(shell_exec('systemctl is-active queue-worker 2>&1'));
$is_running = $worker_status === 'active';
?>
<div class="stat"><div class="stat-value"><?=$cron_count?></div>Active Cronjobs</div>
<div class="stat"><div class="stat-value"><?=$is_running ? '🟢' : '🔴'?></div>Worker <?=$worker_status?></div>
</div>

<div class="card">
<h2>🔴 Redis Stats</h2>
<pre><?=htmlspecialchars(shell_exec('redis-cli info stats 2>/dev/null'))?></pre>
</div>

<div class="card">
<h2>💾 Memory Stats</h2>
<pre><?=htmlspecialchars(shell_exec('redis-cli info memory 2>/dev/null'))?></pre>
</div>

<div class="card">
<h2>💻 System Info</h2>
<pre><?=htmlspecialchars(shell_exec('uptime && free -h'))?></pre>
</div>
</body></html>
MONITORPHP

# 4. Redis Dashboard
cat > "$MONITORING_DIR/redis.php" << 'REDISPHP'
<?php
$redis = new Redis();
if (!$redis->connect('127.0.0.1', 6379)) die('Redis not available');
?>
<!DOCTYPE html><html><head><title>Redis Dashboard</title>
<style>
body{font-family:sans-serif;padding:20px;background:#f5f5f5}
.card{background:white;padding:20px;border-radius:8px;margin:20px 0}
pre{background:#f8f9fa;padding:15px;border-radius:4px}
</style>
</head>
<body>
<h1>🔴 Redis Dashboard</h1>

<div class="card">
<h2>Info</h2>
<pre><?=htmlspecialchars(shell_exec('redis-cli info 2>/dev/null'))?></pre>
</div>

<div class="card">
<h2>Keys</h2>
<pre><?php
$keys = $redis->keys('*');
echo "Total keys: " . count($keys) . "\n\n";
foreach(array_slice($keys, 0, 50) as $key) echo "$key\n";
?></pre>
</div>
</body></html>
REDISPHP

# 5. Worker Control
cat > "$MONITORING_DIR/worker.php" << 'WORKERPHP'
<?php
if (isset($_GET['action'])) {
    $action = $_GET['action'];
    switch($action) {
        case 'start': shell_exec('systemctl start queue-worker'); break;
        case 'stop': shell_exec('systemctl stop queue-worker'); break;
        case 'restart': shell_exec('systemctl restart queue-worker'); break;
        case 'status': header('Content-Type: text/plain'); passthru('systemctl status queue-worker --no-pager'); exit;
    }
    header('Location: ?');
}
?>
<!DOCTYPE html><html><head><title>Worker Control</title>
<style>
body{font-family:sans-serif;padding:20px;background:#f5f5f5}
.card{background:white;padding:20px;border-radius:8px;margin:20px 0}
.btn{display:inline-block;padding:12px 30px;margin:10px;text-decoration:none;border-radius:5px}
.btn-start{background:#28a745;color:white}
.btn-stop{background:#dc3545;color:white}
.btn-restart{background:#ffc107;color:#333}
</style>
</head>
<body>
<h1>🎛️ Worker Control</h1>

<div class="card">
<h3>Actions</h3>
<a href="?action=start" class="btn btn-start">▶️ Start</a>
<a href="?action=stop" class="btn btn-stop">⏹️ Stop</a>
<a href="?action=restart" class="btn btn-restart">🔄 Restart</a>
<a href="?action=status" target="_blank" class="btn" style="background:#007bff;color:white">📋 Status</a>
</div>

<div class="card">
<h3>Logs (last 50 lines)</h3>
<pre><?=htmlspecialchars(shell_exec('tail -50 /var/log/queue_worker.log 2>/dev/null'))?></pre>
</div>
</body></html>
WORKERPHP

# 6. Database Stats
cat > "$MONITORING_DIR/db.php" << 'DBPHP'
<?php
// Database stats dashboard
$config_file = '/var/www/html/application/config/database.php';
if (!file_exists($config_file)) {
    die('Database config not found');
}

require $config_file;
$db = new PDO("mysql:host={$db['default']['hostname']};dbname={$db['default']['database']}", 
              $db['default']['username'], 
              $db['default']['password']);

$tables = $db->query('SHOW TABLES')->fetchAll(PDO::FETCH_COLUMN);
?>
<!DOCTYPE html><html><head><title>DB Stats</title>
<style>
body{font-family:sans-serif;padding:20px;background:#f5f5f5}
.card{background:white;padding:20px;border-radius:8px;margin:20px 0}
table{width:100%;border-collapse:collapse}
th,td{padding:12px;border-bottom:1px solid #ddd}
th{background:#f8f9fa}
</style>
</head>
<body>
<h1>💾 Database Stats</h1>

<div class="card">
<h3>Tables</h3>
<table>
<thead><tr><th>Table</th><th>Rows</th><th>Size</th></tr></thead>
<tbody>
<?php foreach($tables as $table): 
    $size = $db->query("SELECT ROUND((data_length + index_length) / 1024 / 1024, 2) AS size FROM information_schema.TABLES WHERE table_schema = DATABASE() AND table_name = '$table'")->fetch(PDO::FETCH_ASSOC)['size'];
    $count = $db->query("SELECT COUNT(*) FROM `$table`")->fetchColumn();
?>
<tr><td><?=$table?></td><td><?=number_format($count)?></td><td><?=$size?> MB</td></tr>
<?php endforeach; ?>
</tbody>
</table>
</div>
</body></html>
DBPHP

chown -R www-data:www-data "$MONITORING_DIR"
chmod -R 755 "$MONITORING_DIR"

echo "✅ Monitoring dashboards created in $MONITORING_DIR"

