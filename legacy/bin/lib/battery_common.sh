#!/bin/zsh

set -u

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

now_iso() {
  date +"%Y-%m-%dT%H:%M:%S%z"
}

pmset_batt_output() {
  pmset -g batt 2>/dev/null
}

power_source() {
  pmset_batt_output | sed -n "s/^Now drawing from '\(.*\)'/\1/p" | head -n 1
}

battery_percent() {
  pmset_batt_output | sed -n 's/.*[[:space:]]\([0-9][0-9]*\)%;.*/\1/p' | head -n 1
}

battery_state() {
  pmset_batt_output | sed -n 's/.*%; \([^;]*\);.*/\1/p' | head -n 1
}

battery_time_remaining() {
  pmset_batt_output | sed -n 's/.*; \([^;]* remaining\).*/\1/p' | head -n 1
}

system_power_profile() {
  system_profiler SPPowerDataType 2>/dev/null
}

hardware_profile() {
  system_profiler SPHardwareDataType 2>/dev/null
}

sp_value() {
  local key="$1"
  system_power_profile | awk -F': ' -v key="$key" '
    $1 ~ "^[[:space:]]*" key "$" {
      print $2
      exit
    }
  '
}

hw_value() {
  local key="$1"
  hardware_profile | awk -F': ' -v key="$key" '
    $1 ~ "^[[:space:]]*" key "$" {
      print $2
      exit
    }
  '
}

battery_temp_c() {
  ioreg -rn AppleSmartBattery 2>/dev/null | awk -F'= ' '
    /"Temperature"/ {
      gsub(/[^0-9]/, "", $2)
      if ($2 != "") {
        printf "%.1f\n", $2 / 100
      }
      exit
    }
  '
}

ioreg_value() {
  local key="$1"
  ioreg -rn AppleSmartBattery 2>/dev/null | awk -F'= ' -v key="\""${key}"\"" '
    $1 ~ key {
      value=$2
      gsub(/^ +| +$/, "", value)
      gsub(/"/, "", value)
      print value
      exit
    }
  '
}

low_power_value() {
  local scope="$1"
  pmset -g custom 2>/dev/null | awk -v scope="$scope" '
    /^Battery Power:/ { section="battery" }
    /^AC Power:/ { section="ac" }
    section == scope && $1 == "lowpowermode" {
      print $2
      exit
    }
  '
}

display_sleep_value() {
  local scope="$1"
  pmset -g custom 2>/dev/null | awk -v scope="$scope" '
    /^Battery Power:/ { section="battery" }
    /^AC Power:/ { section="ac" }
    section == scope && $1 == "displaysleep" {
      print $2
      exit
    }
  '
}

print_kv() {
  local key="$1"
  local value="${2:-}"
  if [[ -z "$value" ]]; then
    value="unknown"
  fi
  printf "%-26s %s\n" "$key:" "$value"
}
