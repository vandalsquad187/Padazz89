#!/system/bin/sh
# padazz89 repair_assets: Stellt fehlende qx-Server-Dateien aus der installierten APK wieder her
PKG=com.qx.gamingroom
DIR=/storage/emulated/0/Android/data/$PKG/files/server
BASE=""
for ape in $(pm path "$PKG" 2>/dev/null | grep '^package:' | cut -d: -f2); do
  case "$ape" in
    *split*|*:*) : ;;
    *) BASE="$ape"; break ;;
  esac
done

already_ok() {
  [ -e "$DIR/QXToolMain.jar" ]  || return 1
  [ -e "$DIR/libqxserver.so" ]  || return 1
  [ -e "$DIR/qxstart" ]         || return 1
  [ -e "$DIR/462.bin" ]         || return 1
  return 0
}

mkdir -p "$DIR"
if already_ok; then
  exit 0
fi
if [ -z "$BASE" ] || ! unzip -l "$BASE" 2>/dev/null | grep -q 'assets/server/QXToolMain.jar'; then
  exit 0
fi

unzip -o -j "$BASE" 'assets/server/*' -d "$DIR" >/dev/null 2>&1
chmod 755 "$DIR/qxstart" 2>/dev/null

UID_="$(stat -c %u "$DIR" 2>/dev/null)"
GID_="$(stat -c %g "$DIR" 2>/dev/null)"
[ -n "$UID_" ] && chown -R "$UID_:$GID_" "$DIR" 2>/dev/null

already_ok && echo "repair_assets: server-dateien aus APK wiederhergestellt" || echo "repair_assets: wiederherstellung fehlgeschlagen/uebersprungen"