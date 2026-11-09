#!/bin/zsh

set -u

SCRIPT_DIR="${0:A:h}"
. "$SCRIPT_DIR/lib/battery_common.sh"

usage() {
  cat <<'USAGE'
Uso:
  battery_low_power.sh status
  battery_low_power.sh on battery|adapter|all
  battery_low_power.sh off battery|adapter|all

Observacao:
  Alterar pmset pode pedir senha de administrador.
USAGE
}

action="${1:-status}"
scope="${2:-battery}"

if [[ "$action" == "status" ]]; then
  echo "Modo Pouca Energia"
  print_kv "Battery" "$(low_power_value battery)"
  print_kv "Power adapter" "$(low_power_value ac)"
  exit 0
fi

if [[ "$action" != "on" && "$action" != "off" ]]; then
  usage
  exit 2
fi

value="0"
if [[ "$action" == "on" ]]; then
  value="1"
fi

case "$scope" in
  battery)
    sudo pmset -b lowpowermode "$value"
    ;;
  adapter|ac)
    sudo pmset -c lowpowermode "$value"
    ;;
  all)
    sudo pmset -a lowpowermode "$value"
    ;;
  *)
    usage
    exit 2
    ;;
esac

echo "Atualizado."
"$0" status
