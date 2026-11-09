#!/bin/zsh

set -u

SCRIPT_DIR="${0:A:h}"
. "$SCRIPT_DIR/lib/battery_common.sh"

echo "Battery Ops - status"
echo

print_kv "Timestamp" "$(now_iso)"
print_kv "macOS" "$(sw_vers -productVersion 2>/dev/null)"
print_kv "Model" "$(hw_value "Model Name")"
print_kv "Model identifier" "$(hw_value "Model Identifier")"
print_kv "Chip" "$(hw_value "Chip")"
echo

print_kv "Power source" "$(power_source)"
print_kv "Battery percent" "$(battery_percent)%"
print_kv "Battery state" "$(battery_state)"
print_kv "Time remaining" "$(battery_time_remaining)"
print_kv "Battery temp" "$(battery_temp_c) C"
echo

print_kv "Cycle count" "$(sp_value "Cycle Count")"
print_kv "Design cycle count" "$(ioreg_value "DesignCycleCount9C")"
print_kv "Condition" "$(sp_value "Condition")"
print_kv "Maximum capacity" "$(sp_value "Maximum Capacity")"
print_kv "External connected" "$(ioreg_value "ExternalConnected")"
print_kv "Is charging" "$(ioreg_value "IsCharging")"
echo

print_kv "Low power battery" "$(low_power_value battery)"
print_kv "Low power adapter" "$(low_power_value ac)"
print_kv "Display sleep battery" "$(display_sleep_value battery) min"
print_kv "Display sleep adapter" "$(display_sleep_value ac) min"
echo

echo "Top CPU processes"
ps -axo pid,pcpu,pmem,comm | sort -nrk 2 | head -n 8
