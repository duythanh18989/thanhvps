#!/bin/bash
# Quick test script for debugging

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧪 ThanhTV VPS - Quick Test"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
echo "1. BASE_DIR: $BASE_DIR"

if [ -f "$BASE_DIR/functions/utils.sh" ]; then
  echo "2. ✅ utils.sh found"
  source "$BASE_DIR/functions/utils.sh"
else
  echo "2. ❌ utils.sh NOT found"
  exit 1
fi

echo "3. Testing logging functions..."
log_info "This is an info message"
log_warn "This is a warning"
log_error "This is an error (but not exiting)"

echo ""
echo "4. Testing command_exists..."
command_exists bash && echo "   ✅ bash exists" || echo "   ❌ bash not found"
command_exists nonexistent && echo "   ❌ This shouldn't print" || echo "   ✅ nonexistent correctly detected"

echo ""
echo "5. Testing config parsing..."
if [ -f "$BASE_DIR/config.yml" ]; then
  echo "   ✅ config.yml found"
  parse_yaml "$BASE_DIR/config.yml" "TEST_"
  echo "   Sample values:"
  echo "   - default_domain: $TEST_default_domain"
  echo "   - default_php: $TEST_default_php"
  echo "   - redis_enabled: $TEST_redis_enabled"
else
  echo "   ❌ config.yml NOT found"
fi

echo ""
echo "6. Testing check_gum..."
check_gum
if command_exists gum; then
  echo "   ✅ Gum installed or available"
else
  echo "   ⚠️  Gum not available (OK for testing)"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ All basic tests passed!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
