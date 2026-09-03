#!/usr/bin/env bash
# Host an ad hoc IPA over Tailscale HTTPS so a tailnet iPhone can install it.
# Usage: scripts/host-ipa.sh path/to/app.ipa
set -euo pipefail

IPA="${1:?usage: host-ipa.sh <ipa>}"
TS=/Applications/Tailscale.app/Contents/MacOS/Tailscale
HOST=$("$TS" status --json | python3 -c 'import json,sys;print(json.load(sys.stdin)["Self"]["DNSName"].rstrip("."))')
if [ "$("$TS" status --json | python3 -c 'import json,sys;print(bool(json.load(sys.stdin).get("CertDomains")))')" != "True" ]; then
  echo "HTTPS certificates are not enabled for this tailnet. iOS needs HTTPS to install an IPA." >&2
  echo "Enable them at https://login.tailscale.com/admin/dns (HTTPS Certificates), then run this again." >&2
  exit 1
fi
BUNDLE_ID=$(python3 -c 'import json;print(json.load(open("app.json"))["expo"]["ios"]["bundleIdentifier"])')
VERSION=$(python3 -c 'import json;print(json.load(open("app.json"))["expo"]["version"])')
NAME=$(python3 -c 'import json;print(json.load(open("app.json"))["expo"]["name"])')

DIR="$PWD/dist/install"
mkdir -p "$DIR"
cp "$IPA" "$DIR/app.ipa"

cat > "$DIR/manifest.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>items</key><array><dict>
    <key>assets</key><array><dict>
      <key>kind</key><string>software-package</string>
      <key>url</key><string>https://$HOST/app.ipa</string>
    </dict></array>
    <key>metadata</key><dict>
      <key>bundle-identifier</key><string>$BUNDLE_ID</string>
      <key>bundle-version</key><string>$VERSION</string>
      <key>kind</key><string>software</string>
      <key>title</key><string>$NAME</string>
    </dict>
  </dict></array>
</dict></plist>
PLIST

cat > "$DIR/index.html" <<HTML
<!doctype html><meta name="viewport" content="width=device-width">
<body style="font:20px -apple-system;padding:40px;text-align:center">
<h1>$NAME</h1>
<p><a style="display:inline-block;padding:16px 32px;background:#0a7aff;color:#fff;border-radius:12px;text-decoration:none"
   href="itms-services://?action=download-manifest&url=https://$HOST/manifest.plist">Install dev client</a></p>
</body>
HTML

# The GUI Tailscale app cannot serve a folder, only proxy to a local port.
PORT=8765
pkill -f "http.server $PORT" 2>/dev/null || true
(cd "$DIR" && nohup python3 -m http.server "$PORT" --bind 127.0.0.1 > /dev/null 2>&1 &)
sleep 1
"$TS" serve --bg "http://127.0.0.1:$PORT"
echo
echo "Open on your phone: https://$HOST/"
echo "Stop with: pkill -f 'http.server $PORT'; $TS serve reset"
