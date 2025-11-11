#!/bin/bash
# Run Chrome with CORS disabled for development testing

# Kill any existing Chrome processes
killall "Google Chrome" 2>/dev/null || true
killall "Brave Browser" 2>/dev/null || true

# Wait a moment
sleep 2

# Run Chrome/Brave with CORS disabled
if [ -f "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" ]; then
    open -na "Google Chrome" --args \
        --user-data-dir="/tmp/chrome-dev-session" \
        --disable-web-security \
        --disable-site-isolation-trials \
        --disable-features=CrossSiteDocumentBlockingIfIsolating,CrossSiteDocumentBlockingAlways,IsolateOrigins,site-per-process
    echo "✅ Chrome launched with CORS disabled"
elif [ -f "/Applications/Brave Browser.app/Contents/MacOS/Brave Browser" ]; then
    open -na "Brave Browser" --args \
        --user-data-dir="/tmp/brave-dev-session" \
        --disable-web-security \
        --disable-site-isolation-trials \
        --disable-features=CrossSiteDocumentBlockingIfIsolating,CrossSiteDocumentBlockingAlways,IsolateOrigins,site-per-process
    echo "✅ Brave Browser launched with CORS disabled"
else
    echo "❌ Chrome or Brave Browser not found"
    exit 1
fi

echo ""
echo "⚠️  WARNING: This is for DEVELOPMENT ONLY"
echo "   Do NOT use this browser for regular browsing"
echo ""
echo "Now run: flutter run -d chrome"
