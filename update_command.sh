#!/bin/bash
# Quick fix script to update thanhvps command

echo "🔧 Updating thanhvps command..."

# Remove old command
rm -f /usr/local/bin/thanhvps

# Copy new one
if [ -f "./thanhvps" ]; then
  cp ./thanhvps /usr/local/bin/thanhvps
  chmod +x /usr/local/bin/thanhvps
  echo "✅ Updated /usr/local/bin/thanhvps"
else
  echo "❌ thanhvps file not found in current directory"
  exit 1
fi

# Verify
echo ""
echo "📝 File content check:"
grep -A 5 "Parse command" /usr/local/bin/thanhvps

echo ""
echo "✅ Done! Try: thanhvps"
