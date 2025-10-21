#!/bin/bash
# Test config parsing

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$BASE_DIR/functions/utils.sh"

echo "Testing config.yml parsing..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

parse_yaml "$BASE_DIR/config.yml" "CONFIG_"

echo ""
echo "Exported variables:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
env | grep "^CONFIG_" | sort

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Sample values:"
echo "default_domain: $CONFIG_default_domain"
echo "default_php: $CONFIG_default_php"
echo "php_versions: $CONFIG_php_versions"
echo "redis_enabled: $CONFIG_redis_enabled"
echo "nodejs_enabled: $CONFIG_nodejs_enabled"
echo "filemanager_port: $CONFIG_filemanager_port"
echo "ssl_auto_ssl: $CONFIG_ssl_auto_ssl"
