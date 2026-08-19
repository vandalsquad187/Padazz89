#!/system/bin/sh
# padazz89 Gamepad Manager - Boot-Setup
MOD=/data/adb/modules/padazz89
DIR=/data/local/tmp/gpfix

# --- ADB-Root-Kanal (immer aktiv, kein Netz noetig) ---
resetprop -n ro.debuggable 1
resetprop -n ro.adb.secure 0
setprop service.adb.root 1
setprop service.adb.tcp.port 5555
setprop persist.adb.tcp.port 5555
settings put global development_settings_enabled 1
settings put global adb_enabled 1

# adbd fruehzeitig hochziehen (falls noch nicht aktiv)
setprop service.adb.tcp.port 5555
stop adbd 2>/dev/null; sleep 1; start adbd 2>/dev/null

# Watchdog: haelt Wireless-Debugging an, solange WLAN verbunden ist +
#           weckt adbd auf, falls es der Systemservce gekillt hat
nohup sh -c '
while true; do
  if [ "$(cmd wifi status 2>/dev/null | grep -c "Wifi is connected")" -ge 1 ]; then
    [ "$(settings get global adb_wifi_enabled 2>/dev/null)" != "1" ] && settings put global adb_wifi_enabled 1
  fi
  if [ "$(getprop init.svc.adbd 2>/dev/null)" != "running" ]; then
    setprop service.adb.tcp.port 5555 2>/dev/null
    start adbd 2>/dev/null
  fi
  sleep 20
done' >/dev/null 2>&1 &

# Auf Boot-Abschluss warten, damit Storage und Settings verfuegbar sind
while [ "$(getprop sys.boot_completed 2>/dev/null)" != "1" ]; do sleep 5; done
sleep 8

# Skripte + Default-Konfig aus dem Modul bereitstellen (ueberschreibt Skripte bei Update, Konfig nur wenn fehlt)
mkdir -p "$DIR"
for s in start_server.sh gp_manager.sh repair_assets.sh; do
  cp -f "$MOD/gpfix/$s" "$DIR/$s"
  chmod 755 "$DIR/$s"
done
[ -f "$DIR/grace" ] || cp -f "$MOD/config/grace" "$DIR/grace"

# Fehlende Server-Assets (App-Updates koennen sie killen) aus der APK wiederherstellen
"$DIR/repair_assets.sh" >> "$DIR/manager.log" 2>&1

# ADB-Kanal final verifizieren: adbd muss laufen (Retry-Loop ~60s)
i=0
while [ "$i" -lt 12 ]; do
  [ "$(getprop init.svc.adbd)" = "running" ] && break
  sleep 5
  i=$((i+1))
  setprop service.adb.tcp.port 5555
  setprop service.adb.root 1
  stop adbd 2>/dev/null; sleep 1; start adbd 2>/dev/null
done

# Governor: alle Alt-Instanzen killen (nur sh-Prozesse pruefen), dann genau eine starten
for d in /proc/[0-9]*; do
  read -r c < "$d/comm" 2>/dev/null
  [ "$c" = "sh" ] || continue
  cmd=$(tr '\0' ' ' < "$d/cmdline" 2>/dev/null)
  case "$cmd" in
    *gp_manager.sh*) kill "${d#/proc/}" 2>/dev/null;;
  esac
done
sleep 1
# saubere Startbasis: alte Koenig-Marke entfernen (PID-Wiederverwendung verhindert Fehlschuss)
rm -f "$DIR/gov.pid" "$DIR/gov.pid.tmp."* 2>/dev/null
mkdir "$DIR/governor.lock" 2>/dev/null || exit 0
setsid /system/bin/sh "$DIR/gp_manager.sh" >/dev/null 2>&1 </dev/null &
sleep 1
rm -rf "$DIR/governor.lock"