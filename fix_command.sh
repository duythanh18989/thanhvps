#!/bin/bash
# Fix thanhvps command installation

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔧 Fixing thanhvps command"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Find BASE_DIR
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
echo "1. BASE_DIR: $BASE_DIR"

# Check if thanhvps file exists
if [ ! -f "$BASE_DIR/thanhvps" ]; then
  echo "   ❌ thanhvps script not found in $BASE_DIR"
  exit 1
fi

echo "   ✅ thanhvps script found"
echo ""

# Make executable
echo "2. Making script executable..."
chmod +x "$BASE_DIR/thanhvps"
echo "   ✅ Done"
echo ""

# Copy to /usr/local/bin
echo "3. Copying to /usr/local/bin..."
cp "$BASE_DIR/thanhvps" /usr/local/bin/thanhvps
chmod +x /usr/local/bin/thanhvps
echo "   ✅ Done"
echo ""

# Verify
echo "4. Verifying installation..."
if command -v thanhvps &>/dev/null; then
  echo "   ✅ thanhvps command is available"
  echo ""
  echo "5. Testing command..."
  thanhvps version
else
  echo "   ❌ thanhvps command not found"
  echo ""
  echo "   Try: hash -r"
  echo "   Or: source ~/.bashrc"
  echo "   Or: export PATH=/usr/local/bin:$PATH"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Done! Try running: thanhvps"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
