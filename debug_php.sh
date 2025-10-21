#!/bin/bash
# Debug PHP Installation Issues

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🐘 PHP Installation Debugger"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if PPA is added
echo "1. Checking PHP PPA..."
if grep -q "ondrej/php" /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null; then
  echo "   ✅ ondrej/php PPA is added"
else
  echo "   ❌ ondrej/php PPA is NOT added"
  echo "   Adding now..."
  add-apt-repository ppa:ondrej/php -y
  apt-get update -y
fi

echo ""
echo "2. Checking available PHP versions..."
for ver in 7.4 8.1 8.2 8.3; do
  if apt-cache show "php${ver}" &>/dev/null; then
    echo "   ✅ PHP ${ver} is available in repos"
  else
    echo "   ❌ PHP ${ver} is NOT available"
  fi
done

echo ""
echo "3. Testing installation of PHP 8.2..."
echo "   Command: apt-get install -y php8.2 php8.2-fpm php8.2-cli"
echo ""

apt-get install -y php8.2 php8.2-fpm php8.2-cli 2>&1 | tee /tmp/php_test.log

if [ ${PIPESTATUS[0]} -eq 0 ]; then
  echo ""
  echo "   ✅ PHP 8.2 installed successfully"
  php8.2 -v
else
  echo ""
  echo "   ❌ PHP 8.2 installation failed"
  echo "   Check log: /tmp/php_test.log"
  echo ""
  echo "   Last 20 lines of error:"
  tail -20 /tmp/php_test.log
fi

echo ""
echo "4. Checking installed PHP versions..."
dpkg -l | grep php | grep -E "^ii" | awk '{print $2}'

echo ""
echo "5. Checking PHP-FPM services..."
systemctl list-units --type=service | grep php

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
