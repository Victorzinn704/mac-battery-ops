#!/bin/zsh

set -u

SCRIPT_DIR="${0:A:h}"
ROOT_DIR="${SCRIPT_DIR:h}"
. "$SCRIPT_DIR/lib/battery_common.sh"

LOG_DIR="$ROOT_DIR/logs"
LOG_FILE="$LOG_DIR/battery_log.csv"

mkdir -p "$LOG_DIR"

if [[ ! -f "$LOG_FILE" ]]; then
  echo "timestamp,power_source,percent,state,time_remaining,cycle_count,condition,max_capacity,battery_temp_c,external_connected,is_charging,low_power_battery,low_power_adapter" > "$LOG_FILE"
fi

timestamp="$(now_iso)"
source="$(power_source)"
percent="$(battery_percent)"
state="$(battery_state)"
remaining="$(battery_time_remaining)"
cycles="$(sp_value "Cycle Count")"
condition="$(sp_value "Condition")"
max_capacity="$(sp_value "Maximum Capacity")"
temp_c="$(battery_temp_c)"
external_connected="$(ioreg_value "ExternalConnected")"
is_charging="$(ioreg_value "IsCharging")"
low_power_battery="$(low_power_value battery)"
low_power_adapter="$(low_power_value ac)"

printf '%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n' \
  "$timestamp" \
  "$source" \
  "$percent" \
  "$state" \
  "$remaining" \
  "$cycles" \
  "$condition" \
  "$max_capacity" \
  "$temp_c" \
  "$external_connected" \
  "$is_charging" \
  "$low_power_battery" \
  "$low_power_adapter" >> "$LOG_FILE"

echo "Log salvo em: $LOG_FILE"
