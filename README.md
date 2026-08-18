# padazz89 (Gamepad Manager)

Shanwan Gamepad Plus "jailbreak": Aktivierung ohne WLAN, der qx-Server laeuft nur solange
der BT-Controller verbunden ist (0% Last im Idle, Stopp 3 Min nach Trennen).

Manuell aus: `su -c "echo off > /data/local/tmp/gpfix/policy"`

---

Root-Module (Magisk / KernelSU) fuer den automatisierten Betrieb des Gamepad-Plus-Servers
von ShanWan (`com.qx.gamingroom`) auf Android.

**Funktionen**

- **Ohne WLAN aktivieren** — ADB-Root-Kanal laeuft dauerhaft, die App-Aktivierung
  funktioniert dadurch auch wenn Wireless-Debugging nicht an ist.
- **On-Demand-Server** — Der qx-Server `app_process64` laeuft NUR solange der BT-Controller
  verbunden ist. Kein Controller = 0 CPU-Last, keine Batterie.
- **Auto-Stop** — 3 Minuten nach dem Trennen des Controllers wird der Server sauber beendet.
- **Offline-first** — Die App braucht keinen laufenden Server mehr zum „Aktivieren";
  der Start passiert automatisch sobald der Controller da ist.
- **Asset-Repair** — Fehlende Server-Dateien (`QXToolMain.jar`, `libqxserver.so`, ...,
  z.B. nach App-Updates) werden beim Boot automatisch aus der installierten APK wiederhergestellt.
- **ADB-TCP-Watchdog** — haelt `adb_wifi_enabled=1` solange WLAN verbunden ist.
- **Log-Rotation** — `manager.log` rotiert bei 64 KB (`manager.log.1`).

## Installation

1. ZIP-Datei aus den [Releases](https://github.com/vandalsquad187/Padazz89/releases) laden.
2. In **Magisk** oder **KernelSU** (Module > from storage) installieren.
3. Reboot.
4. Controller verbinden -> Server startet automatisch. Fertig.

> Hinweis: Die App muss mindestens einmal geoeffnet/gemappt gewesen sein, damit
> `Android/data/com.qx.gamingroom/files/server` existiert.

## Konfiguration (Hot-Reload)

Dateien liegen unter `/data/local/tmp/gpfix/`:

| Datei      | Wirkung                                                                 |
|------------|-------------------------------------------------------------------------|
| `policy`   | Inhalt `off` = Governor pausiert (nur manueller Betrieb). Loeschen reaktiviert. |
| `grace`    | Gnadenzeit in 5-Sekunden-Zyklen. Default `36` (= 3 Min). Beispiel `60` = 5 Min. |

```sh
su -c 'echo off > /data/local/tmp/gpfix/policy'   # Temporär ausschalten
su -c 'rm /data/local/tmp/gpfix/policy'           # Wieder aktivieren
su -c 'echo 60 > /data/local/tmp/gpfix/grace'     # Gnade auf 5 Minuten
```

## Fortschritt / Troubleshooting

```sh
su -c 'pgrep -af "gp_manager[.]sh"'               # laeuft der Governor?
su -c 'pgrep -af "app_process6[4]"'               # laeuft der Server?
su -c 'tail -5 /data/local/tmp/gpfix/manager.log' # Log prüfen
```

## Struktur

```
module.prop  id deklaration (padazz89)
service.sh   Boot-Setup: ADB-Kanal, Watchdog, Asset-Repair, Governor-Start
gpfix/       start_server.sh (Server-Launcher / app_process64)
             gp_manager.sh  (Governor v4: On-Demand-Start/Stop)
             repair_assets.sh (stellt Server-Assets aus APK wieder her)
config/      grace          (Default-Konfiguration)
```

Nicht fuer kommerzielle Nutzung. Viel Spass damit. :)