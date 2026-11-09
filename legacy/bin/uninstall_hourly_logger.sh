#!/bin/zsh

set -u

PLIST="$HOME/Library/LaunchAgents/com.codex.battery-ops.logger.plist"

if [[ -f "$PLIST" ]]; then
  launchctl unload "$PLIST" >/dev/null 2>&1 || true
  rm -f "$PLIST"
  echo "Logger horario removido."
else
  echo "Logger horario nao estava instalado."
fi
