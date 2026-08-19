#!/system/bin/sh
# padazz89 gp_manager v5.3 (Governor)
# Startet/stoppt den Gamepad-Plus-Server NACH BEDARF (0% Last ohne Controller).
# v5.3: Koenigswahl inkl. cmdline-Pruefung - PID-Wiederverwendung nach Reboot
#       wird als stale erkannt und uebernommen (atomares mv, Konvergenz in 1 Runde).
# Konfig (hot-reload): DIR/policy=off = pause, DIR/grace = Zyklen * 5s
DIR=/data/local/tmp/gpfix
SRV_FILE=$DIR/start_server.sh
LOCK=$DIR/server.lock
LOG=$DIR/manager.log
POLICY=$DIR/policy
GRACE_FILE=$DIR/grace
GOVPID=$DIR/gov.pid

log() {
  if [ -f "$LOG" ] && [ "$(wc -c < "$LOG" 2>/dev/null || echo 0)" -gt 65536 ]; then
    mv -f "$LOG" "$LOG.1" 2>/dev/null
  fi
  echo "[$(date '+%F %T')] $*" >> "$LOG"
}

# Koenigswahl: nur eine lebende Governor-Instanz. Fremde PID ohne Governor-cmdline = stale.
lead() {
  if [ -r "$GOVPID" ]; then
    OLD=$(cat "$GOVPID" 2>/dev/null)
    if [ -n "$OLD" ] && [ "$OLD" != "$$" ] && [ -d "/proc/$OLD" ]; then
      cmd=$(tr '\0' ' ' < "/proc/$OLD/cmdline" 2>/dev/null)
      case "$cmd" in
        *gp_manager.sh*) exit 0;;
      esac
    fi
  fi
  echo "$$" > "$GOVPID.tmp.$$" 2>/dev/null || exit 0
  mv -f "$GOVPID.tmp.$$" "$GOVPID" 2>/dev/null || exit 0
}

lead

server_pids() {
  R=""
  for d in /proc/[0-9]*; do
    if [ -r "$d/comm" ] && grep -q "^anwan.gamepad:i$" "$d/comm"; then
      R="$R ${d#/proc/}"
    fi
  done
  echo "$R"
}

start_server_once() {
  [ -n "$(server_pids)" ] && return 0
  mkdir "$LOCK" 2>/dev/null || return 0
  setsid /system/bin/sh "$SRV_FILE" >/dev/null 2>&1 </dev/null &
  sleep 2
  rm -rf "$LOCK" 2>/dev/null
  if [ -n "$(server_pids)" ]; then
    log "server gestartet (controller verbunden)"
  fi
}

controller_connected() {
  dumpsys input 2>/dev/null | grep -q 'Wireless Controller'
}

idle=0
while true; do
  lead

  GRACE=$(cat "$GRACE_FILE" 2>/dev/null || echo 36)
  case "$GRACE" in ''|*[!0-9]*) GRACE=36;; esac
  [ "$GRACE" -lt 1 ] && GRACE=1

  if [ "$(cat "$POLICY" 2>/dev/null)" = "off" ]; then
    sleep 30
    continue
  fi

  if controller_connected; then
    if [ -z "$(server_pids)" ]; then
      start_server_once
    fi
    idle=0
  else
    [ -n "$(server_pids)" ] && idle=$((idle+1))
    if [ "$idle" -ge "$GRACE" ] && [ -n "$(server_pids)" ]; then
      for p in $(server_pids); do
        kill "$p" 2>/dev/null
      done
      log "server beendet (controller getrennt, gnade abgelaufen)"
      idle=0
    fi
  fi
  sleep 5
done