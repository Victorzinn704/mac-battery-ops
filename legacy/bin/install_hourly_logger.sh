#!/bin/zsh

set -u

SCRIPT_DIR="${0:A:h}"
ROOT_DIR="${SCRIPT_DIR:h}"
PLIST="$HOME/Library/LaunchAgents/com.codex.battery-ops.logger.plist"
LOG_STDOUT="$ROOT_DIR/logs/launchd.out.log"
LOG_STDERR="$ROOT_DIR/logs/launchd.err.log"

mkdir -p "$HOME/Library/LaunchAgents"
mkdir -p "$ROOT_DIR/logs"

cat > "$PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.codex.battery-ops.logger</string>
  <key>ProgramArguments</key>
  <array>
    <string>$SCRIPT_DIR/battery_log.sh</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>StartInterval</key>
  <integer>3600</integer>
  <key>StandardOutPath</key>
  <string>$LOG_STDOUT</string>
  <key>StandardErrorPath</key>
  <string>$LOG_STDERR</string>
</dict>
</plist>
PLIST

launchctl unload "$PLIST" >/dev/null 2>&1 || true
launchctl load "$PLIST"

echo "Logger horario instalado: $PLIST"
echo "CSV: $ROOT_DIR/logs/battery_log.csv"
