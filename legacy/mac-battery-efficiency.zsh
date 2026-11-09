#!/bin/zsh

set -u

requested_action="${1:-status}"
if [[ "$requested_action" != "status" && "${MAC_BATTERY_ALLOW_CHANGES:-0}" != "1" ]]; then
  echo "Plan only: set MAC_BATTERY_ALLOW_CHANGES=1 to use this legacy automation." >&2
  exit 64
fi
set -- "$requested_action"

export PATH="/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin"

typeset -r USER_HOME="${HOME}"
typeset -r USER_ID="$(/usr/bin/id -u)"
typeset -r STATE_DIR="${USER_HOME}/.local/state/mac-efficiency"
typeset -r LOG_FILE="${STATE_DIR}/efficiency.log"
typeset -r LAST_MODE_FILE="${STATE_DIR}/last-mode"
typeset -r UI_SNAPSHOT_FILE="${STATE_DIR}/ui-defaults.tsv"
typeset -r STOPPED_APPS_FILE="${STATE_DIR}/stopped-apps.txt"
typeset -r STOPPED_JOBS_FILE="${STATE_DIR}/stopped-jobs.txt"
typeset -r LOCK_DIR="${STATE_DIR}/run.lock"

typeset -a MANAGED_APPS
MANAGED_APPS=(
  "Atoll"
  "DockDoor"
  "Ice"
  "Maccy"
  "Parsec"
)

typeset -a MANAGED_JOBS
MANAGED_JOBS=(
  "com.joao.ai-gateway|${USER_HOME}/Library/LaunchAgents/com.joao.ai-gateway.plist"
  "com.joao.ai-local-model|${USER_HOME}/Library/LaunchAgents/com.joao.ai-local-model.plist"
  "com.joao.repertorio-mesa|${USER_HOME}/Library/LaunchAgents/com.joao.repertorio-mesa.plist"
  "com.google.GoogleUpdater.wake|${USER_HOME}/Library/LaunchAgents/com.google.GoogleUpdater.wake.plist"
)

mkdir -p "${STATE_DIR}"

log_message() {
  /usr/bin/printf '%s %s\n' "$(/bin/date '+%Y-%m-%d %H:%M:%S')" "$*" >> "${LOG_FILE}"
}

detect_mode() {
  local power_line
  power_line="$(/usr/bin/pmset -g batt | /usr/bin/head -n 1)"

  if [[ "${power_line}" == *"Battery Power"* ]]; then
    /usr/bin/printf 'battery\n'
  else
    /usr/bin/printf 'ac\n'
  fi
}

read_last_mode() {
  if [[ -f "${LAST_MODE_FILE}" ]]; then
    /bin/cat "${LAST_MODE_FILE}"
  fi
}

record_line_once() {
  local value="$1"
  local target_file="$2"

  /usr/bin/touch "${target_file}"
  if ! /usr/bin/grep -Fqx -- "${value}" "${target_file}"; then
    /usr/bin/printf '%s\n' "${value}" >> "${target_file}"
  fi
}

snapshot_bool() {
  local domain="$1"
  local key="$2"
  local raw_value
  local stored_value

  if raw_value="$(/usr/bin/defaults read "${domain}" "${key}" 2>/dev/null)"; then
    case "${raw_value}" in
      1|true|TRUE|yes|YES) stored_value="1" ;;
      *) stored_value="0" ;;
    esac
  else
    stored_value="__MISSING__"
  fi

  /usr/bin/printf '%s\t%s\t%s\n' "${domain}" "${key}" "${stored_value}" >> "${UI_SNAPSHOT_FILE}"
}

snapshot_ui_defaults() {
  /bin/rm -f "${UI_SNAPSHOT_FILE}"
  snapshot_bool "NSGlobalDomain" "NSAutomaticWindowAnimationsEnabled"
  snapshot_bool "com.apple.dock" "launchanim"
  snapshot_bool "com.apple.dock" "show-recents"
}

apply_efficient_ui() {
  /usr/bin/defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false
  /usr/bin/defaults write com.apple.dock launchanim -bool false
  /usr/bin/defaults write com.apple.dock show-recents -bool false

  /usr/bin/killall Dock >/dev/null 2>&1 || true
  /usr/bin/killall SystemUIServer >/dev/null 2>&1 || true
  log_message "battery: reduced window animations and Dock extras"
}

restore_ui_defaults() {
  local domain
  local key
  local stored_value

  if [[ ! -f "${UI_SNAPSHOT_FILE}" ]]; then
    return
  fi

  while IFS=$'\t' read -r domain key stored_value; do
    # Older snapshots may contain protected Accessibility preferences.
    [[ "${domain}" == "com.apple.universalaccess" ]] && continue

    if [[ "${stored_value}" == "__MISSING__" ]]; then
      /usr/bin/defaults delete "${domain}" "${key}" >/dev/null 2>&1 || true
    elif [[ "${stored_value}" == "1" ]]; then
      /usr/bin/defaults write "${domain}" "${key}" -bool true
    else
      /usr/bin/defaults write "${domain}" "${key}" -bool false
    fi
  done < "${UI_SNAPSHOT_FILE}"

  /bin/rm -f "${UI_SNAPSHOT_FILE}"
  /usr/bin/killall Dock >/dev/null 2>&1 || true
  /usr/bin/killall SystemUIServer >/dev/null 2>&1 || true
  log_message "ac: restored previous interface defaults"
}

job_is_loaded() {
  local label="$1"
  /bin/launchctl print "gui/${USER_ID}/${label}" >/dev/null 2>&1
}

pause_job() {
  local job_spec="$1"
  local label="${job_spec%%|*}"
  local plist_path="${job_spec#*|}"

  if job_is_loaded "${label}"; then
    record_line_once "${job_spec}" "${STOPPED_JOBS_FILE}"
    /bin/launchctl bootout "gui/${USER_ID}" "${plist_path}" >/dev/null 2>&1 || \
      /bin/launchctl bootout "gui/${USER_ID}/${label}" >/dev/null 2>&1 || true
    log_message "battery: paused job ${label}"
  fi
}

resume_jobs() {
  local job_spec
  local label
  local plist_path

  if [[ ! -f "${STOPPED_JOBS_FILE}" ]]; then
    return
  fi

  while IFS= read -r job_spec; do
    [[ -z "${job_spec}" ]] && continue
    label="${job_spec%%|*}"
    plist_path="${job_spec#*|}"

    if [[ -f "${plist_path}" ]] && ! job_is_loaded "${label}"; then
      /bin/launchctl bootstrap "gui/${USER_ID}" "${plist_path}" >/dev/null 2>&1 || true
      log_message "ac: resumed job ${label}"
    fi
  done < "${STOPPED_JOBS_FILE}"

  : > "${STOPPED_JOBS_FILE}"
}

app_is_running() {
  local app_name="$1"
  /usr/bin/pgrep -f "/Applications/${app_name}.app/" >/dev/null 2>&1
}

pause_app() {
  local app_name="$1"

  if app_is_running "${app_name}"; then
    record_line_once "${app_name}" "${STOPPED_APPS_FILE}"
    /usr/bin/pkill -TERM -f "/Applications/${app_name}.app/" >/dev/null 2>&1 || true
    log_message "battery: quit background app ${app_name}"
  fi
}

resume_apps() {
  local app_name
  local app_path

  if [[ ! -f "${STOPPED_APPS_FILE}" ]]; then
    return
  fi

  while IFS= read -r app_name; do
    [[ -z "${app_name}" ]] && continue
    app_path="/Applications/${app_name}.app"

    if [[ -d "${app_path}" ]] && ! app_is_running "${app_name}"; then
      /usr/bin/open -gja "${app_path}" >/dev/null 2>&1 || true
      log_message "ac: reopened background app ${app_name}"
    fi
  done < "${STOPPED_APPS_FILE}"

  : > "${STOPPED_APPS_FILE}"
}

stop_local_ai_processes() {
  /usr/bin/pkill -TERM -f "${USER_HOME}/.local/bin/llama-server" >/dev/null 2>&1 || true
  /usr/bin/pkill -TERM -f "${USER_HOME}/test/scripts/ryzen-ai-lab/scripts/mac/run_litellm.sh" >/dev/null 2>&1 || true
}

apply_battery_mode() {
  local previous_mode="$1"
  local job_spec
  local app_name

  if [[ "${previous_mode}" != "battery" ]]; then
    snapshot_ui_defaults
    apply_efficient_ui
    log_message "entered strict battery-efficiency mode"
  fi

  for job_spec in "${MANAGED_JOBS[@]}"; do
    pause_job "${job_spec}"
  done

  stop_local_ai_processes

  for app_name in "${MANAGED_APPS[@]}"; do
    pause_app "${app_name}"
  done
}

apply_ac_mode() {
  local previous_mode="$1"

  if [[ "${previous_mode}" == "battery" ]]; then
    restore_ui_defaults
    resume_jobs
    resume_apps
    log_message "entered charger mode and restored paused services"
  fi
}

print_status() {
  local detected_mode
  local last_mode
  local job_spec
  local label
  local app_name
  local state

  detected_mode="$(detect_mode)"
  last_mode="$(read_last_mode)"
  [[ -z "${last_mode}" ]] && last_mode="not-applied"

  /usr/bin/printf 'Power source: %s\n' "${detected_mode}"
  /usr/bin/printf 'Applied mode: %s\n' "${last_mode}"
  /usr/bin/pmset -g batt
  /usr/bin/printf '\nManaged jobs:\n'

  for job_spec in "${MANAGED_JOBS[@]}"; do
    label="${job_spec%%|*}"
    if job_is_loaded "${label}"; then state="running"; else state="stopped"; fi
    /usr/bin/printf '  %-38s %s\n' "${label}" "${state}"
  done

  /usr/bin/printf '\nManaged background apps:\n'
  for app_name in "${MANAGED_APPS[@]}"; do
    if app_is_running "${app_name}"; then state="running"; else state="stopped"; fi
    /usr/bin/printf '  %-38s %s\n' "${app_name}" "${state}"
  done
}

requested_mode="${1:-auto}"

if [[ "${requested_mode}" == "status" ]]; then
  print_status
  exit 0
fi

if ! /bin/mkdir "${LOCK_DIR}" 2>/dev/null; then
  exit 0
fi
trap '/bin/rmdir "${LOCK_DIR}" >/dev/null 2>&1 || true' EXIT INT TERM

previous_mode="$(read_last_mode)"

case "${requested_mode}" in
  auto) active_mode="$(detect_mode)" ;;
  battery|ac) active_mode="${requested_mode}" ;;
  *)
    /usr/bin/printf 'Usage: %s [auto|battery|ac|status]\n' "$0" >&2
    exit 64
    ;;
esac

case "${active_mode}" in
  battery) apply_battery_mode "${previous_mode}" ;;
  ac) apply_ac_mode "${previous_mode}" ;;
esac

/usr/bin/printf '%s\n' "${active_mode}" > "${LAST_MODE_FILE}"
