# 🚀 ThanhTV VPS - Quick Reference

## Command Line Usage

### Basic Commands

```bash
# Open menu
thanhvps
thanhvps menu
thanhvps m

# Show help
thanhvps help
thanhvps h

# Show version
thanhvps version
thanhvps v

# Show system status
thanhvps info
thanhvps status
```

### Website Management

```bash
# Add new website
thanhvps website add
thanhvps web add
thanhvps w add

# Remove website
thanhvps website remove
thanhvps web rm

# List all websites
thanhvps website list
thanhvps web ls
```

### Database Management

```bash
# Create database
thanhvps database create
thanhvps db create
thanhvps d create

# Delete database
thanhvps database delete
thanhvps db rm

# List databases
thanhvps database list
thanhvps db ls

# Export database
thanhvps database export
thanhvps db backup
```

### System Management

```bash
# Open system menu
thanhvps system
thanhvps sys

# Restart all services
thanhvps restart

# Run backup
thanhvps backup
thanhvps bk

# Update script
thanhvps update
thanhvps up
```

### Logs

```bash
# View Nginx logs
thanhvps logs nginx

# View PHP logs
thanhvps logs php
thanhvps logs php 8.1

# View MySQL logs
thanhvps logs mysql

# View Redis logs
thanhvps logs redis

# View installation log
thanhvps logs install
```

---

## Quick Tasks

### Add a Website

```bash
thanhvps website add
# Then follow prompts:
# - Enter domain name
# - Choose PHP version
# - Optionally install SSL
```

### Create a Database

```bash
thanhvps db create
# Then follow prompts:
# - Enter database name
# - Enter username (or use same as DB name)
# - Enter password (or auto-generate)
# - Enter MySQL root password
```

### Backup Everything

```bash
thanhvps backup
# Choose option 1 to backup all
```

### Check System Status

```bash
thanhvps info
```

Output example:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 ThanhTV VPS Status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📦 Version: 2.0.0
📂 Base Dir: /root/thanhvps

🔧 Services:
  ✅ Nginx: Running
  ✅ PHP 8.2: Running
  ✅ MariaDB: Running
  ✅ Redis: Running
  ✅ NodeJS: v20.10.0

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Restart All Services

```bash
thanhvps restart
```

---

## File Locations

### Configuration
- Main config: `/root/thanhvps/config.yml`
- Nginx config: `/etc/nginx/nginx.conf`
- Nginx sites: `/etc/nginx/sites-available/`
- PHP config: `/etc/php/8.2/fpm/php.ini`

### Website Files
- Web root: `/var/www/domain.com/public_html/`
- Nginx logs: `/var/log/nginx/domain.com.*.log`

### Database
- MySQL config: `/etc/mysql/mariadb.conf.d/50-server.cnf`
- MySQL data: `/var/lib/mysql/`

### Backups
- Website backups: `/opt/backups/sites/`
- Database backups: `/opt/backups/mysql/`

### Logs
- Installation: `~/thanhvps/logs/install.log`
- Nginx: `/var/log/nginx/`
- PHP: `/var/log/php8.2-fpm.log`
- MySQL: `/var/log/mysql/error.log`
- Redis: `/var/log/redis/redis-server.log`

---

## Common Tasks

### Change PHP Version for Website

Edit Nginx config:
```bash
nano /etc/nginx/sites-available/domain.com.conf
```

Change this line:
```nginx
fastcgi_pass unix:/run/php/php8.2-fpm.sock;
```

To:
```nginx
fastcgi_pass unix:/run/php/php8.1-fpm.sock;
```

Then reload:
```bash
nginx -t && systemctl reload nginx
```

### Check Service Status

```bash
systemctl status nginx
systemctl status php8.2-fpm
systemctl status mariadb
systemctl status redis-server
```

### Manual Nginx Test

```bash
nginx -t                    # Test config
systemctl reload nginx      # Reload without downtime
systemctl restart nginx     # Full restart
```

### Connect to MySQL

```bash
mysql -u root -p
```

### Redis Commands

```bash
redis-cli ping              # Test connection
redis-cli INFO              # Get info
redis-cli FLUSHALL          # Clear all cache
```

---

## Troubleshooting

### Command not found

```bash
# Re-install command
sudo cp ~/thanhvps/thanhvps /usr/local/bin/
sudo chmod +x /usr/local/bin/thanhvps
```

### Services not starting

```bash
# Check logs
thanhvps logs nginx
thanhvps logs php
thanhvps logs mysql

# Try restart
thanhvps restart
```

### Website 502 Bad Gateway

```bash
# Check PHP-FPM
systemctl status php8.2-fpm

# Check socket
ls -la /run/php/php8.2-fpm.sock

# Restart
systemctl restart php8.2-fpm
systemctl reload nginx
```

### Database connection error

```bash
# Check MySQL
systemctl status mariadb

# Check password
cat ~/thanhvps/logs/install.log | grep mysql_root_password
```

---

## Tips & Tricks

### Alias for faster access

Add to `~/.bashrc`:
```bash
alias tvps='thanhvps'
alias tvps-add='thanhvps website add'
alias tvps-db='thanhvps db create'
alias tvps-restart='thanhvps restart'
```

Then reload:
```bash
source ~/.bashrc
```

### Auto backup with cron

```bash
# Edit crontab
crontab -e

# Add daily backup at 2:30 AM
30 2 * * * /usr/local/bin/thanhvps backup >/dev/null 2>&1
```

### Monitor logs in real-time

```bash
# Terminal 1: Nginx access
tail -f /var/log/nginx/domain.com.access.log

# Terminal 2: PHP errors
tail -f /var/log/php8.2-fpm.log

# Terminal 3: MySQL
tail -f /var/log/mysql/error.log
```

---

## Security Checklist

- [ ] Change MySQL root password after installation
- [ ] Setup UFW firewall: `ufw enable && ufw allow 22,80,443/tcp`
- [ ] Install Fail2ban: `apt install fail2ban`
- [ ] Change SSH port (optional)
- [ ] Disable root SSH login (optional)
- [ ] Setup auto-updates: `apt install unattended-upgrades`
- [ ] Regular backups: `thanhvps backup`
- [ ] Monitor logs regularly

---

For full documentation, see: [README.md](README_NEW.md)
