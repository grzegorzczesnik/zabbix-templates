# Zabbix Template: SNMP QNAP TVS-473e

An optimized, native SNMP template for QNAP NAS devices (tested on TVS-473e and TS-251). Designed for production environments: SNMP polling of system health, storage and network, SNMP traps for QTS events, advanced JavaScript preprocessing, context macros and dependency trees to prevent alert fatigue.

**Template version:** 4.0.0 (Release)  
**Requires:** Zabbix 8.0+  
**Author:** Grzegorz Cześnik (grzegorz@net59.pl)

---

## ✅ What's New in Version 4.0.0 (vs 3.0.0)

Versions 3.1.0–3.4.0 were internal work versions and were not published; 4.0.0 contains all their changes. Item keys of existing items are unchanged, so history is kept, but trigger names and some tags changed – read *Upgrade notes* before importing.
* **Storage pools** (new rule *Storage Pool Discovery*, QTS-MIB pool table): total capacity, free space and utilization per pool with *Low* (Warning) and *Critically low* (High) free space triggers. Snapshots and thin volumes use pool free space, so a full pool stops snapshots and writes to thin volumes even when the volumes still show free space.
* **Fill-up forecast:** *Will be full in less than N days* for every storage pool and volume (`timeleft()` over the last 7 days), thresholds `{$POOL.FULL.DAYS.WARN}` / `{$VFS.FULL.DAYS.WARN}` (30 days) with context. Closes when the forecast is longer than twice the threshold; suppressed while *Critically low free space* is open.
* **Exact sizes:** volumes and external USB/eSATA drives in bytes from the QTS-MIB volume table (`1.3.6.1.4.1.55062.1.10.9.1`) instead of parsing rounded text such as `665.64 GB`.
* **Volume status:** new item *{volume}: Status* and trigger *Status is not Ready* (High) – e.g. a volume that went read-only.
* **Memory without cache:** new item *Memory: Available* (HOST-RESOURCES-MIB `hrStorage`); *Memory utilization* is based on the kernel estimate of available memory (as in the Zabbix Linux templates), new trigger *High memory utilization* above `{$MEMORY.UTIL.MAX}` (90 %) for 5 minutes.
* **Network interfaces under macro control:** *High error rate* only above `{$NET.IF.ERRORS.WARN}` errors/s for 5 minutes (was: any error; High → Warning, with hysteresis); *Interface is down* can be switched off per port with `{$NET.IF.CONTROL:"eth3"}` = 0.
* **USB drives no longer break drive discovery:** a connected USB drive appears in the QTS drive table and made *Physical Drive Discovery* fail; it is now filtered out (`{$QNAP.DRIVE.ENC.EXCLUDE}`). New item *Serial number* for every drive, to identify the drive before a replacement.
* **"Open QTS" link** in 24 triggers (menu of the problem) – `{$QNAP.WEB.SCHEME}://{HOST.CONN}:{$QNAP.WEB.PORT}/`.
* **Consistent names, tags and dependencies:** every trigger name ends with `on {HOST.NAME}`, sentence case, *No SNMP data collection* (as in the Zabbix templates), no changing values in trigger names (they are in operational data), *No data* triggers tagged `scope: availability`; SMB and QTS web checks depend only on *Host is unavailable*, fan speed depends on fan failure, hysteresis on drive temperatures and bandwidth.
* **Dashboard:** storage health row (SMART, RAID, pools) on *System Overview*, *QTS events (SNMP traps)* list, mirrored *Network Traffic* graph, *Temperatures* graph, *Free Space* and *Pool Free Space* honeycombs, *Interface Health* list; colours match the trigger thresholds, one palette on all pages.
* Smaller fixes: *RAID N: Free space* disabled by default (QTS reports 0), *Is global spare* polled hourly, QM2 cards get no temperature item, the single-item drive temperature pie graph is removed, English comments in all JavaScript.

## ✅ What's New in Version 3.0.0 (vs 2.0.1)

* **SNMP traps for QTS events**, split into Error (High), Warning and other (Information). The QTS message is shown in the problem name, and the QTS module (e.g. `Security Center`) goes into the `qts_module` tag.
* **No hard-coded thresholds:** new macros `{$NET.IF.UTIL.MAX}`, `{$FAN.SPEED.MIN}`, `{$EXT.FREE.MIN}`.
* **Fewer false and duplicate alerts:** RAID `Initializing` no longer raises a false Critical, *Interface is down* closes automatically, duplicate system temperature trigger disabled, permanently open *External Drive Connected* problem removed.
* **Consistent naming and documentation:** shortened volume names (`QTS (Pool 1)`), `component` + `scope` tags everywhere, EN/PL descriptions on every object.
* **Zabbix 8.0 export format.**

Full list: [CHANGELOG.md](CHANGELOG.md).

---

## ⬆️ Upgrade notes (3.0.0 → 4.0.0)

* **Import over 3.0.0** keeps history: no key of an existing item has changed. New items: pools, *Memory: Available*, volume *Status*, drive *Serial number*.
* **Renamed triggers** – check actions and filters that use trigger names. Problems that are already open keep their old names.

  | 3.0.0 | 4.0.0 |
  |---|---|
  | *Drive Health is NOT Good* | *SMART status is not Good* |
  | *High Error Rate (Cable/Switch failure?)* | *High error rate (>… errors/s for 5m)* |
  | *SNMP Agent is unreachable* | *No SNMP data collection* |
  | *Fan N: System reports failure (Error Code: …)* | *Fan N: System reports failure* (code in operational data) |
  | *USB Drive Error: …* | *USB drive {label} (port N): Status is not Ready* |
  | *USB Drive Low Space: …* | *USB drive {label} (port N): Low free space (<…%)* |
  | *SMB Service is Down*, other names | sentence case, e.g. *SMB service is down*; all names end with `on {HOST.NAME}` |

* **Renamed external drive items:** `USB drive {label} (port N): Free space / Total size / Status` (keys unchanged).
* **`scope` tag:** *No data* triggers of components, SMART, fans and RAID changed from `health` to `availability` – check action conditions on `scope = health`.
* ***High error rate*** is Warning (was High) and fires only above `{$NET.IF.ERRORS.WARN}` errors/s.
* **Values jump slightly** after the first poll from the QTS-MIB table: volumes and external drives in exact bytes instead of a rounded `xx.xx GB` (up to 0.08 % on the test NAS, 2026-11-25).
* **Memory utilization rises slightly:** calculated from *Memory: Available* instead of *Memory: Free*; on the test NAS about +3 percentage points (55.9 % → 58.8 %, 2026-11-26).
* **Fill-up forecasts need history:** *Will be full…* uses the last 7 days; right after the upgrade it may be based on fewer values.
* **Drive slot labels:** `HDD1`, `HDD2`… come from the legacy NAS-MIB slot table. On the test NAS `HDD1`–`HDD4` = 3.5" bays 1–4 and `HDD5`–`HDD6` = M.2 slots of the QM2 card (verified 2026-11-27). After the upgrade compare *Serial number* with QTS (*Storage & Snapshots → Disks/VJBOD*).
* **New elements verified on TVS-473e** (QTS 5.2, 2026-11-26/27) **and checked on TS-251** (2026-11-27, `snmpget` of the first volume and pool): QTS-MIB volume status and sizes, `hrStorage` *Available memory* (index 11). USB drives on QTS-MIB were verified on TVS-473e only. On other models check them with `snmpget` before relying on them.
* **HTTPS to QTS:** set `{$QNAP.WEB.SCHEME}` = `https` and `{$QNAP.WEB.PORT}` (e.g. `443`) on the host, otherwise *Open QTS* opens `http://…:8080/`.

## ⬆️ Upgrade notes (2.x → 3.0.0)

* **Zabbix 8.0 is required.** The file cannot be imported into Zabbix 7.4. If you are still on 7.4, stay on 2.0.1.
* **History is kept.** Item keys are unchanged, so importing 3.0.0 over 2.0.1 updates the existing items. Discovered items get new (shortened) names after the next discovery run.
* **Context macros for volumes** still use the full QTS volume name, e.g. `{$VFS.FREE.MIN.WARN:"[Volume QTS, Pool 1]"}` – host overrides from 2.x keep working.
* **Traps are optional.** Without the trap receiver (see below) the three trap items simply stay empty; everything else works as before.
* **Thresholds you changed in the template** (`80` %, `200` RPM, `10` %) are now macros – set them on the host instead of editing triggers.

---

## 📡 SNMP traps (QTS events)

QTS sends an SNMP trap (QTS-MIB, enterprise `1.3.6.1.4.1.55062`) for each event it logs. The template splits them by trap type:

| Item | Key | Trigger | Severity |
|---|---|---|---|
| `System: Last SNMP trap (Error)` | `snmptrap["55062\.1\.12\.2\.0\.4\b"]` | QNAP error | High |
| `System: Last SNMP trap (Warning)` | `snmptrap["55062\.1\.12\.2\.0\.2\b"]` | QNAP warning | Warning |
| `System: Last SNMP trap (other)` | `snmptrap.fallback` | QNAP SNMP trap (other) | Information |

Each trap opens its own problem (*Multiple* mode) and the problem is **closed manually** – there is no recovery event for a QTS log entry.

### Requirements on the Zabbix server or proxy that monitors the NAS (tested on Debian 12 and 13)

1. **snmptrapd** (Debian: `snmptrapd` package) with the Zabbix handler:
   ```
   snmpTrapdAddr udp:0.0.0.0:162
   authCommunity log,execute,net <your_community>
   traphandle default /bin/bash /usr/local/sbin/zabbix_trap_handler.sh
   ```
   The file holds the community, but `snmptrapd` reads it already as `Debian-snmp`: set `root:Debian-snmp` and `0640`. With `0600 root:root` it accepts no traps at all (see *Known issues*).
2. **Handler** `zabbix_trap_handler.sh` from the official [zabbix-docker](https://github.com/zabbix/zabbix-docker) repository (branch `8.0`, `templates/scripts/snmptraps/zabbix_trap_handler.sh`), with two local changes:
   * `ZABBIX_TRAPS_FILE` pointing to a file **outside `/var/log/zabbix`** (e.g. `/var/log/zabbix-snmptraps/snmptraps.log`) – see *Known issues*;
   * the agent-address match extended to the numeric form printed without MIBs:
     ```
     if [[ "$oid" =~ (^|::)snmpTrapAddress\.0$ ]] || [[ "$oid" =~ ^\.?1\.3\.6\.1\.6\.3\.18\.1\.3\.0$ ]] || [[ "$oid" =~ ^iso\.3\.6\.1\.6\.3\.18\.1\.3\.0$ ]]; then
     ```
3. **Trap file permissions:** on Debian `snmptrapd` runs as `Debian-snmp`. Directory `Debian-snmp:zabbix 0750`, file `Debian-snmp:zabbix 0640`; in logrotate use `su Debian-snmp zabbix` and `create 0640 Debian-snmp zabbix`.
4. **Zabbix server/proxy configuration:**
   ```
   SNMPTrapperFile=/var/log/zabbix-snmptraps/snmptraps.log
   StartSNMPTrapper=1
   ```
5. **Start at boot:** on Debian `snmptrapd.service` is `static` and is started by `snmptrapd.socket` only when the first trap arrives. To have the process running right after boot: `sudo systemctl add-wants multi-user.target snmptrapd.service`.
6. **Firewall:** allow UDP 162 from the NAS address only.
7. **QTS:** *Control Panel → Network & File Services → SNMP* – *Trap Address 1* = the server/proxy address, trap levels *Warning* and *Error*. QTS sends traps with the same community that it uses for polling. Traps were tested on TVS-473e (QTS 5.2) and TS-251; both use the same QTS-MIB format.

**Test without the NAS** (on the server/proxy):
```
snmptrap -v1 -c '<your_community>' 127.0.0.1 1.3.6.1.4.1.55062.1.12.2 <NAS_IP> 6 2 '' 1.3.6.1.4.1.55062.1.12.1.102.0 s "[Test] Warning trap"
```
A *QNAP warning: [Test] Warning trap* problem with tag `qts_module: Test` should appear on the host.

---

## ⚙️ Macros

Volume, pool and interface macros support context, so you can set thresholds for a single volume, pool or port on the host (e.g. `{$VFS.FREE.MIN.WARN:"[Volume QTS, Pool 1]"}`, `{$POOL.FREE.MIN.WARN:"2"}` – the pool context is the pool number from QTS).

| Macro | Default | Description |
|---|---|---|
| `{$CPU.UTIL.CRIT}` | `90` | Critical CPU utilization (%), checked as the 10-minute average. |
| `{$EXT.FREE.MIN}` | `10` | Low free space threshold for external USB/eSATA drives (%). |
| `{$FAN.SPEED.MIN}` | `200` | Minimum fan speed (RPM); below it the fan is treated as stopped. |
| `{$MEMORY.UTIL.MAX}` | `90` | Memory utilization threshold (%) without cache and buffers, as a 5-minute minimum. |
| `{$NET.IF.CONTROL}` | `1` | Alert when an interface goes down: 1 = yes, 0 = no. Context per interface, e.g. `{$NET.IF.CONTROL:"eth3"}` = 0 for a port that is intentionally not connected. |
| `{$NET.IF.ERRORS.WARN}` | `2` | Packet error rate per interface (errors/s), inbound or outbound, as a 5-minute minimum. Context per interface. |
| `{$NET.IF.IFNAME.MATCHES}` | `^eth[0-3]$` | Regular expression for physical network interfaces to discover. |
| `{$NET.IF.IFNAME.NOT_MATCHES}` | `(veth\|vnet\|docker\|lo\|lxc\|qvs\|dummy\|tun)` | Regular expression excluding virtual interfaces from discovery. |
| `{$NET.IF.UTIL.MAX}` | `80` | Interface utilization threshold (%), inbound or outbound, as a 10-minute minimum. |
| `{$POOL.FREE.MIN.CRIT}` | `10` | Critically low free space in a storage pool (%). |
| `{$POOL.FREE.MIN.WARN}` | `20` | Low free space in a storage pool (%). |
| `{$POOL.FULL.DAYS.WARN}` | `30` | Warn when a pool is forecast to be full within this many days (trend of the last 7 days). Context per pool. |
| `{$QNAP.DRIVE.ENC.EXCLUDE}` | `^33$` | Regular expression of QNAP enclosure IDs skipped by *Physical Drive Discovery* (33 = USB on QTS 5.2). |
| `{$QNAP.WEB.PORT}` | `8080` | TCP port of the QTS web interface, used by the service check and the *Open QTS* link. |
| `{$QNAP.WEB.SCHEME}` | `http` | Scheme of the QTS web interface (`http` or `https`), used by the *Open QTS* link. |
| `{$TEMP.CPU.CRIT}` | `85` | Critical CPU temperature (°C). |
| `{$TEMP.DISK.CRIT}` | `60` | Critical drive temperature (°C). |
| `{$TEMP.DISK.WARN}` | `50` | Warning drive temperature (°C). |
| `{$TEMP.SYSTEM.CRIT}` | `65` | Critical system (motherboard) temperature (°C). |
| `{$VFS.FREE.MIN.CRIT}` | `10` | Critically low free space on a volume (%). |
| `{$VFS.FREE.MIN.WARN}` | `20` | Low free space on a volume (%). |
| `{$VFS.FULL.DAYS.WARN}` | `30` | Warn when a volume is forecast to be full within this many days (trend of the last 7 days). Context per volume. |

**SNMP community:** keep it out of the template. Set the host SNMP interface community to `{$SNMP_COMMUNITY}` and define that macro on the host as *Secret text*. Do not use `public`.

---

## 🔍 Low-Level Discovery (LLD) Rules

* **Ethernet Interface Discovery**: In/Out traffic, speed (`ifHighSpeed`), errors, discards and operational state (virtual interfaces filtered out); error threshold and *Interface is down* controlled per port by macros.
* **System Component Discovery**: Temperatures of the main unit and expansion units. *An LLD override creates no temperature item or triggers for QM2 PCIe cards (they report `-100`).*
* **CPU Core Discovery**: Utilization per CPU core.
* **Disk Performance Discovery**: IOPS and latency per logical volume.
* **Physical Drive Discovery**: Temperatures, capacity, SMART codes and status, serial number for internal drives (HDD/SSD, NVMe on QM2 cards); USB drives are skipped (`{$QNAP.DRIVE.ENC.EXCLUDE}`), so they have no serial number item; temperature triggers with 5 °C hysteresis.
* **External Drive Discovery (USB/eSATA)**: Status, total size and free space in exact bytes (QTS-MIB volume table, same index as the legacy table – verified 2026-11-27 with a USB drive); names show the volume label and the USB port, e.g. `USB drive BACKUP (port 4): Free space`.
* **Fan Discovery**: RPM and fan controller status.
* **Storage Pool Discovery**: Total capacity, free space and utilization per storage pool (QTS-MIB), low free space triggers and fill-up forecast.
* **RAID Group Discovery**: Array status (QTS states mapped to numeric codes), capacity and rebuild progress. *Free space* is disabled by default (QTS reports 0).
* **Logical Volume Discovery**: Free space, total size (exact bytes from the QTS-MIB volume table `1.3.6.1.4.1.55062.1.10.9.1`; names from the legacy table, same index – verified 2026-11-25 on 17 volumes) and utilization, volume status (*Status is not Ready*), low free space triggers and fill-up forecast.

---

## 🚨 Triggers

All trigger names end with `on {HOST.NAME}` (omitted below). `{volume}` stands for the shortened volume name, e.g. `QTS (Pool 1)`. *Open QTS* = link to the QTS web interface in the problem menu. *No data* triggers depend on *Host is unavailable* and *No SNMP data collection*; *Low free space* and *Will be full* depend on *Critically low free space* of the same pool or volume; drive *Temperature is high* depends on *Temperature is critical*.

| Source | Trigger | Severity | `scope` | Open QTS | Note |
|---|---|---|---|---|---|
| Template | `Host is unavailable` | Disaster | availability |  |  |
| Template | `SMB service is down` | High | availability |  |  |
| Template | `QTS web interface is down` | Average | availability |  |  |
| Template | `CPU usage data is not responding (No data)` | Average | availability |  |  |
| Template | `High CPU utilization for 10 minutes` | Warning | performance |  |  |
| Template | `QNAP SNMP trap (other)` | Information | health | ✓ |  |
| Template | `QNAP warning` | Warning | health | ✓ |  |
| Template | `QNAP error` | High | health | ✓ |  |
| Template | `CPU temperature is high ({ITEM.VALUE1})` | Warning | health | ✓ |  |
| Template | `CPU temperature sensor is not responding (No data)` | Average | availability |  |  |
| Template | `Firmware version has changed` | Information | audit | ✓ |  |
| Template | `System temperature is high ({ITEM.VALUE1})` | Warning | health |  | disabled |
| Template | `System temperature sensor is not responding (No data)` | Average | availability |  |  |
| Template | `System has been restarted` | Warning | availability | ✓ |  |
| Template | `Memory metrics are not responding (No data)` | Average | availability |  |  |
| Template | `High memory utilization (>{$MEMORY.UTIL.MAX}% for 5m)` | Average | performance | ✓ |  |
| Template | `No SNMP data collection` | Average | availability |  |  |
| Ethernet Interface | `{#IFNAME}: Interface speed changed` | Information | performance |  |  |
| Ethernet Interface | `{#IFNAME}: Interface is down` | High | availability |  |  |
| Ethernet Interface | `{#IFNAME}: High bandwidth utilization (>{$NET.IF.UTIL.MAX}%)` | Warning | performance |  |  |
| Ethernet Interface | `{#IFNAME}: High error rate (>{$NET.IF.ERRORS.WARN:"{#IFNAME}"} errors/s for 5m)` | Warning | health |  |  |
| System Component | `{#COMPNAME}: Temperature is high ({ITEM.VALUE1})` | Warning | health | ✓ |  |
| System Component | `{#COMPNAME}: Temperature sensor is not responding (No data)` | Average | availability |  |  |
| Physical Drive | `{#DRIVESLOT}: SMART status is not Good` | High | health | ✓ |  |
| Physical Drive | `{#DRIVESLOT}: SMART status is not responding (No data)` | Average | availability |  |  |
| Physical Drive | `{#DRIVESLOT}: Temperature is critical ({ITEM.VALUE1})` | High | health | ✓ |  |
| Physical Drive | `{#DRIVESLOT}: Temperature is high ({ITEM.VALUE1})` | Warning | health | ✓ |  |
| Physical Drive | `{#DRIVESLOT}: Temperature sensor is not responding (No data)` | Average | availability |  |  |
| External Drive | `USB drive {#EXTLABEL} (port N): Connected` | Information | availability |  | not discovered |
| External Drive | `USB drive {#EXTLABEL} (port N): Status is not Ready` | High | health | ✓ |  |
| External Drive | `USB drive {#EXTLABEL} (port N): Low free space (<{$EXT.FREE.MIN}%)` | Average | capacity | ✓ |  |
| Fan | `Fan {#FANID}: Speed is too low or stopped ({ITEM.VALUE1})` | High | health | ✓ |  |
| Fan | `Fan {#FANID}: Speed sensor is not responding (No data)` | Average | availability |  |  |
| Fan | `Fan {#FANID}: System reports failure` | High | health | ✓ |  |
| Storage Pool | `Pool {#POOLID}: Will be full in less than {$POOL.FULL.DAYS.WARN:"{#POOLID}"} days` | Warning | capacity | ✓ |  |
| Storage Pool | `Pool {#POOLID}: Critically low free space` | High | capacity | ✓ |  |
| Storage Pool | `Pool {#POOLID}: Low free space` | Warning | capacity | ✓ |  |
| RAID Group | `RAID {#RAIDID}: Maintenance or synchronization in progress` | Warning | health | ✓ |  |
| RAID Group | `RAID {#RAIDID}: Status is critical (Degraded/Failed)` | High | health | ✓ |  |
| RAID Group | `RAID {#RAIDID}: Status is not responding (No data)` | Average | availability |  |  |
| Logical Volume | `{volume}: Will be full in less than {$VFS.FULL.DAYS.WARN:"{#VOLUMENAME}"} days` | Warning | capacity | ✓ |  |
| Logical Volume | `{volume}: Status is not Ready` | High | health | ✓ |  |
| Logical Volume | `{volume}: Critically low free space` | High | capacity | ✓ |  |
| Logical Volume | `{volume}: Low free space` | Warning | capacity | ✓ |  |

---

## 📊 Dashboard

Built-in multi-page dashboard (slideshow can be started manually):
* **System Overview:** model, uptime, firmware, Ping/SNMP availability; gauges for CPU, CPU and system temperature, memory; storage health row (drive SMART, RAID groups, pool utilization); *Active Alerts* and *QTS events (SNMP traps)* with the `qts_module` tag.
* **Storage: Physical:** SMART status honeycomb (all drives, including M.2 on QM2 cards), drive temperature graph with trigger lines, hottest drives.
* **Storage: Logical:** RAID group status and space utilization of volumes and pools, free space per pool and per volume, IOPS and latency graphs.
* **Network & Services:** interface status, mirrored traffic graph (in above, out below zero), *Interface Health* (speed and errors per port; yellow on any error, red from 2 errors/s), SMB and QTS web availability.
* **Hardware Health:** CPU and system temperature over time, per-core utilization, fan status and speed.

---

## ⚙️ Installation & Best Practices

1. Download `SNMP QNAP TVS-473e.yaml`.
2. In Zabbix 8.0 go to **Data collection → Templates → Import**.
3. Link the template to the QNAP host; enable SNMPv2c in QTS and use your own community (host macro `{$SNMP_COMMUNITY}`, *Secret text*).
4. **CRITICAL:** in the host SNMP interface **uncheck `Use bulk requests`**. The QTS SNMP daemon drops bulk requests under heavy I/O, which causes false `[no data]` problems.
5. Set `Timeout` on the Zabbix server/proxy to at least `10s`.
6. Optional: configure the trap receiver (section *SNMP traps*).

---

## ⚠️ Known issues

| Symptom | Cause | Workaround |
|---|---|---|
| QTS reports an NVMe drive on a QM2 card as SAS | This is how QTS reports it over SNMP | Handled: *Drive type* replaces SAS with NVMe (verified on WD Red SN700 in QM2-2P-244A, 2026-11-19). Side effect: a real SAS drive would also be shown as NVMe |
| Traps never reach the file; `journalctl -u snmptrapd` shows *Permission denied* | On Debian `snmptrapd` runs as `Debian-snmp`, not as root | Owner `Debian-snmp:zabbix` on the trap file and its directory (see *Requirements*, point 3) |
| `snmptrapd` is `active`, but the journal says *no access control information configured … will NOT accept any incoming notifications* | `snmptrapd` cannot read `snmptrapd.conf` (e.g. `0600 root:root`), so it does not see `authCommunity` | `root:Debian-snmp`, `0640` on `snmptrapd.conf`, restart `snmptrapd` and check the journal |
| After a reboot of the server/proxy the `snmptrapd` process is not running | `snmptrapd.service` is `static`; `snmptrapd.socket` starts it only when the first trap arrives | `sudo systemctl add-wants multi-user.target snmptrapd.service` |
| Traps stop arriving after a Zabbix package upgrade | The Zabbix package post-install script runs `chown -R zabbix:zabbix /var/log/zabbix` on every install and upgrade, so `snmptrapd` (`Debian-snmp`) can no longer write the trap file there | Keep the trap file outside `/var/log/zabbix` (e.g. `/var/log/zabbix-snmptraps/`) |
| Trap shows up only as `ZBXTRAP 127.0.0.1` / unmatched | Handler does not recognise `iso.3.6.1.6.3.18.1.3.0` when no MIBs are loaded | Use the extended regular expression from the *SNMP traps* section |
| `\"` in problem names | QTS messages containing quotes are escaped by `snmptrapd` | Cosmetic |
| `snmpwalk`/`snmpget` returns *Timeout* | Wrong community or SNMP disabled in QTS | Compare the community in QTS with `{$SNMP_COMMUNITY}` on the host |
| *RAID N: Free space* shows 0 B | QTS reports free space of the RAID group, which is fully allocated to a pool | Disabled by default since 4.0.0; use *Pool N: Free space* |
| *Storage Pool Discovery* finds nothing or its items are *Not supported* | Not seen so far: the QTS-MIB pool table answers on TVS-473e (QTS 5.2, 2026-11-24) and TS-251 (2026-11-27). An older QTS version may not have it | Check with `snmpwalk -v2c -c '<COMMUNITY>' <NAS-IP> 1.3.6.1.4.1.55062.1.10.7.1.2` – it must list the pools. If not, disable the rule on that host |
| Pool free space differs from volume free space | A pool holds volumes, snapshots and reserved space – two different measurements | Expected |
| Dashboard colours do not follow a threshold changed on the host (e.g. `{$TEMP.CPU.CRIT}`) | Thresholds in dashboard widgets are fixed numbers, not macros | Edit the widget thresholds in the template dashboard as well |
| *Will be full in less than N days* does not fire right after linking, or fires after a one-off large copy | `timeleft()` extrapolates the free space trend of the last 7 days | Expected; it closes by itself when the forecast is longer than twice the threshold |
| *Open QTS* opens the wrong address | The link uses `{HOST.CONN}` (address of the host SNMP interface), `{$QNAP.WEB.SCHEME}` and `{$QNAP.WEB.PORT}` | Set the two macros on the host; the SNMP interface must use the address under which QTS is reachable from your browser |
| *Status is not Ready* fires for a short operation (e.g. a volume check) | Only `Ready` was observed (17 volumes, 2026-11-26); other QTS status texts are not known, so every other text raises the problem | Close it manually if expected; report the status text so it can be handled |
| *Memory: Available* is *Not supported* or shows a wrong value | Not seen so far: index 11 of `hrStorage` is *Available memory* on TVS-473e (QTS 5.2, 2026-11-26) and TS-251 (2026-11-27). Another QTS version or model may have no such entry or have it at another index | Check with `snmpget -v2c -c '<COMMUNITY>' <NAS-IP> 1.3.6.1.2.1.25.2.3.1.3.11` – the answer must be `"Available memory"`. If not, disable *Memory: Available*, *Memory utilization* and *High memory utilization* on that host |
| *Physical Drive Discovery* shows *item prototype with the same key already exists* while a USB drive is connected | 3.x: a USB drive appears in the QTS drive table without a slot label | Fixed in 4.0.0 by the filter `{$QNAP.DRIVE.ENC.EXCLUDE}` (`^33$`, USB enclosure on QTS 5.2). If your USB enclosure has another ID (QTS-MIB `1.3.6.1.4.1.55062.1.10.34`), change the macro on the host |
| Drives on a QM2 card are named `HDD5`, `HDD6`; an SSD added to an internal M.2 slot may shift the labels | Slot labels come from the legacy NAS-MIB slot table, joined to the drive table by index | Compare *Serial number* with QTS (*Storage & Snapshots → Disks/VJBOD*) after every drive change |
| After a USB drive is ejected its items show *Not supported* (*No Such Instance currently exists at this OID*) | The volume is gone from the SNMP tables; observed 2026-11-27 | Expected. After the next *External Drive Discovery* run (up to 1h) the items are marked as not discovered and kept for 365 days (`lifetime: 365d`, never disabled), so history stays. When the same drive was plugged into the same port again (2026-11-27), QTS gave it the same SNMP index and the same items resumed with continuous history; a different drive or port may get another index and new items |
| USB drive name shows `()` or an empty label | The volume has no label (QTS-MIB column 8) or the QTS name has no `Drive: '…'` part | Cosmetic; item keys use the SNMP index |

---

## 📝 Changelog

See [CHANGELOG.md](CHANGELOG.md).

<br>
<br>

***
<br>
<br>

# Szablon Zabbix: SNMP QNAP TVS-473e

Zoptymalizowany, natywny szablon SNMP dla serwerów NAS firmy QNAP (testowany na modelach TVS-473e oraz TS-251). Zaprojektowany dla środowisk produkcyjnych: odpytywanie SNMP stanu systemu, pamięci masowej i sieci, pułapki SNMP ze zdarzeniami QTS, preprocessing JavaScript, makra z kontekstem oraz drzewa zależności, aby zapobiegać fałszywym alarmom.

**Wersja szablonu:** 4.0.0 (Release)  
**Wymagania:** Zabbix 8.0+  
**Autor:** Grzegorz Cześnik (grzegorz@net59.pl)

---

## ✅ Co nowego w wersji 4.0.0 (względem 3.0.0)

Wersje 3.1.0–3.4.0 były wewnętrznymi wersjami roboczymi i nie zostały opublikowane; 4.0.0 zawiera wszystkie ich zmiany. Klucze istniejących itemów bez zmian, więc historia zostaje, ale zmieniły się nazwy triggerów i część tagów – przed importem przeczytaj *Uwagi do aktualizacji*.
* **Pule pamięci** (nowa reguła *Storage Pool Discovery*, tabela pul QTS-MIB): pojemność, wolne miejsce i zajętość każdej puli z triggerami *Low* (Warning) i *Critically low* (High). Migawki i wolumeny thin korzystają z wolnego miejsca puli, więc pełna pula zatrzymuje migawki i zapis na wolumenach thin, nawet gdy wolumeny pokazują jeszcze wolne miejsce.
* **Prognoza zapełnienia:** *Will be full in less than N days* dla każdej puli i wolumenu (`timeleft()` z ostatnich 7 dni), progi `{$POOL.FULL.DAYS.WARN}` / `{$VFS.FULL.DAYS.WARN}` (30 dni) z kontekstem. Zamyka się, gdy prognoza przekroczy dwukrotność progu; wstrzymana, gdy otwarty jest *Critically low free space*.
* **Dokładne rozmiary:** wolumeny i dyski zewnętrzne USB/eSATA w bajtach z tabeli wolumenów QTS-MIB (`1.3.6.1.4.1.55062.1.10.9.1`) zamiast parsowania zaokrąglonego tekstu typu `665.64 GB`.
* **Status wolumenu:** nowy item *{volume}: Status* i trigger *Status is not Ready* (High) – np. wolumen przełączony w tryb tylko do odczytu.
* **Pamięć bez cache:** nowy item *Memory: Available* (HOST-RESOURCES-MIB `hrStorage`); *Memory utilization* liczone z szacunku jądra o dostępnej pamięci (jak w szablonach Zabbix dla Linuksa), nowy trigger *High memory utilization* powyżej `{$MEMORY.UTIL.MAX}` (90 %) przez 5 minut.
* **Interfejsy sieciowe sterowane makrami:** *High error rate* dopiero powyżej `{$NET.IF.ERRORS.WARN}` błędów/s przez 5 minut (było: każdy błąd; High → Warning, z histerezą); *Interface is down* można wyłączyć dla portu makrem `{$NET.IF.CONTROL:"eth3"}` = 0.
* **Dyski USB nie psują już odkrywania dysków:** podłączony dysk USB pojawia się w tabeli dysków QTS i powodował błąd *Physical Drive Discovery*; teraz jest odfiltrowany (`{$QNAP.DRIVE.ENC.EXCLUDE}`). Nowy item *Serial number* dla każdego dysku, żeby rozpoznać dysk przed wymianą.
* **Link „Open QTS”** w 24 triggerach (menu problemu) – `{$QNAP.WEB.SCHEME}://{HOST.CONN}:{$QNAP.WEB.PORT}/`.
* **Spójne nazwy, tagi i zależności:** każda nazwa triggera kończy się na `on {HOST.NAME}`, małe litery w środku nazw, *No SNMP data collection* (jak w szablonach Zabbix), bez zmiennych wartości w nazwach triggerów (są w operational data), triggery *No data* z tagiem `scope: availability`; testy SMB i WWW QTS zależą tylko od *Host is unavailable*, prędkość wentylatora od jego awarii, histereza temperatur dysków i obciążenia łącza.
* **Dashboard:** rząd stanu pamięci masowej (SMART, RAID, pule) na *System Overview*, lista *QTS events (SNMP traps)*, lustrzany wykres *Network Traffic*, wykres *Temperatures*, kafelki *Free Space* i *Pool Free Space*, lista *Interface Health*; kolory zgodne z progami triggerów, jedna paleta na wszystkich stronach.
* Drobne poprawki: *RAID N: Free space* domyślnie wyłączony (QTS raportuje 0), *Is global spare* odpytywany co godzinę, karty QM2 bez itemu temperatury, usunięty wykres kołowy temperatury jednego dysku, komentarze po angielsku w całym JavaScript.

## ✅ Co nowego w wersji 3.0.0 (względem 2.0.1)

* **Pułapki SNMP ze zdarzeniami QTS** z podziałem na Error (High), Warning i pozostałe (Information). Treść komunikatu QTS trafia do nazwy problemu, a moduł QTS (np. `Security Center`) do tagu `qts_module`.
* **Bez progów wpisanych na sztywno:** nowe makra `{$NET.IF.UTIL.MAX}`, `{$FAN.SPEED.MIN}`, `{$EXT.FREE.MIN}`.
* **Mniej fałszywych i zdublowanych alarmów:** RAID w stanie `Initializing` nie daje już fałszywego Critical, *Interface is down* zamyka się sam, zdublowany trigger temperatury systemu wyłączony, usunięty stale otwarty problem *External Drive Connected*.
* **Spójne nazwy i dokumentacja:** skrócone nazwy wolumenów (`QTS (Pool 1)`), tagi `component` + `scope` wszędzie, opisy EN/PL w każdym obiekcie.
* **Format eksportu Zabbix 8.0.**

Pełna lista: [CHANGELOG.md](CHANGELOG.md).

---

## ⬆️ Uwagi do aktualizacji (3.0.0 → 4.0.0)

* **Import na 3.0.0** zachowuje historię: żaden klucz istniejącego itemu się nie zmienił. Nowe itemy: pule, *Memory: Available*, *Status* wolumenu, *Serial number* dysku.
* **Zmienione nazwy triggerów** – sprawdź akcje i filtry po nazwie triggera. Problemy już otwarte zachowują stare nazwy.

  | 3.0.0 | 4.0.0 |
  |---|---|
  | *Drive Health is NOT Good* | *SMART status is not Good* |
  | *High Error Rate (Cable/Switch failure?)* | *High error rate (>… errors/s for 5m)* |
  | *SNMP Agent is unreachable* | *No SNMP data collection* |
  | *Fan N: System reports failure (Error Code: …)* | *Fan N: System reports failure* (kod w operational data) |
  | *USB Drive Error: …* | *USB drive {etykieta} (port N): Status is not Ready* |
  | *USB Drive Low Space: …* | *USB drive {etykieta} (port N): Low free space (<…%)* |
  | *SMB Service is Down*, inne nazwy | małe litery w środku, np. *SMB service is down*; wszystkie nazwy kończą się na `on {HOST.NAME}` |

* **Zmienione nazwy itemów dysków zewnętrznych:** `USB drive {etykieta} (port N): Free space / Total size / Status` (klucze bez zmian).
* **Tag `scope`:** triggery *No data* komponentów, SMART, wentylatorów i RAID zmienione z `health` na `availability` – sprawdź warunki akcji na `scope = health`.
* ***High error rate*** ma ważność Warning (było High) i zgłasza się dopiero powyżej `{$NET.IF.ERRORS.WARN}` błędów/s.
* **Wartości lekko skaczą** po pierwszym odczycie z tabeli QTS-MIB: wolumeny i dyski zewnętrzne w dokładnych bajtach zamiast zaokrąglonego `xx.xx GB` (do 0,08 % na testowym NAS-ie, 25.11.2026).
* **Memory utilization lekko rośnie:** liczone z *Memory: Available* zamiast *Memory: Free*; na testowym NAS-ie o ok. 3 punkty procentowe (55,9 % → 58,8 %, 26.11.2026).
* **Prognozy zapełnienia potrzebują historii:** *Will be full…* korzysta z ostatnich 7 dni; zaraz po aktualizacji może opierać się na mniejszej liczbie wartości.
* **Etykiety slotów dysków:** `HDD1`, `HDD2`… pochodzą ze starszej tabeli slotów NAS-MIB. Na testowym NAS-ie `HDD1`–`HDD4` = zatoki 3.5" 1–4, a `HDD5`–`HDD6` = gniazda M.2 karty QM2 (sprawdzone 27.11.2026). Po aktualizacji porównaj *Serial number* z QTS (*Pamięć masowa i migawki → Dyski/VJBOD*).
* **Nowe elementy sprawdzone na TVS-473e** (QTS 5.2, 26–27.11.2026) **i na TS-251** (27.11.2026, `snmpget` pierwszego wolumenu i puli): status i rozmiary wolumenów z QTS-MIB, *Available memory* z `hrStorage` (indeks 11). Dyski USB na QTS-MIB sprawdzone tylko na TVS-473e. Na innych modelach sprawdź je `snmpget` przed poleganiem na nich.
* **HTTPS do QTS:** ustaw na hoście `{$QNAP.WEB.SCHEME}` = `https` i `{$QNAP.WEB.PORT}` (np. `443`), inaczej *Open QTS* otworzy `http://…:8080/`.

## ⬆️ Uwagi do aktualizacji (2.x → 3.0.0)

* **Wymagany Zabbix 8.0.** Pliku nie da się zaimportować do Zabbix 7.4. Jeśli nadal używasz 7.4, zostań przy 2.0.1.
* **Historia zostaje.** Klucze itemów się nie zmieniły, więc import 3.0.0 na 2.0.1 aktualizuje istniejące itemy. Wykryte itemy dostaną nowe (skrócone) nazwy po najbliższym odkryciu.
* **Makra z kontekstem dla wolumenów** nadal używają pełnej nazwy wolumenu z QTS, np. `{$VFS.FREE.MIN.WARN:"[Volume QTS, Pool 1]"}` – ustawienia na hostach z wersji 2.x działają dalej.
* **Pułapki są opcjonalne.** Bez odbiornika pułapek (patrz niżej) trzy itemy pułapek po prostu pozostają puste; reszta działa jak wcześniej.
* **Progi zmieniane w szablonie** (`80` %, `200` RPM, `10` %) są teraz makrami – ustawiaj je na hoście zamiast edytować triggery.

---

## 📡 Pułapki SNMP (zdarzenia QTS)

QTS wysyła pułapkę SNMP (QTS-MIB, enterprise `1.3.6.1.4.1.55062`) dla każdego zdarzenia, które zapisuje w dzienniku. Szablon dzieli je według typu pułapki:

| Item | Klucz | Trigger | Ważność |
|---|---|---|---|
| `System: Last SNMP trap (Error)` | `snmptrap["55062\.1\.12\.2\.0\.4\b"]` | QNAP error | High |
| `System: Last SNMP trap (Warning)` | `snmptrap["55062\.1\.12\.2\.0\.2\b"]` | QNAP warning | Warning |
| `System: Last SNMP trap (other)` | `snmptrap.fallback` | QNAP SNMP trap (other) | Information |

Każda pułapka otwiera osobny problem (tryb *Multiple*), a problem **zamyka się ręcznie** – wpis w dzienniku QTS nie ma zdarzenia przywrócenia.

### Wymagania na serwerze lub proxy Zabbix, które monitoruje NAS (sprawdzone na Debianie 12 i 13)

1. **snmptrapd** (Debian: pakiet `snmptrapd`) z handlerem Zabbix:
   ```
   snmpTrapdAddr udp:0.0.0.0:162
   authCommunity log,execute,net <twoje_community>
   traphandle default /bin/bash /usr/local/sbin/zabbix_trap_handler.sh
   ```
   W pliku jest community, ale `snmptrapd` czyta go już jako `Debian-snmp`: ustaw `root:Debian-snmp` i `0640`. Przy `0600 root:root` nie przyjmuje żadnej pułapki (patrz *Znane problemy*).
2. **Handler** `zabbix_trap_handler.sh` z oficjalnego repozytorium [zabbix-docker](https://github.com/zabbix/zabbix-docker) (gałąź `8.0`, `templates/scripts/snmptraps/zabbix_trap_handler.sh`), z dwiema lokalnymi zmianami:
   * `ZABBIX_TRAPS_FILE` wskazuje plik **poza `/var/log/zabbix`** (np. `/var/log/zabbix-snmptraps/snmptraps.log`) – patrz *Znane problemy*;
   * rozpoznawanie adresu agenta rozszerzone o postać liczbową wypisywaną bez MIB-ów:
     ```
     if [[ "$oid" =~ (^|::)snmpTrapAddress\.0$ ]] || [[ "$oid" =~ ^\.?1\.3\.6\.1\.6\.3\.18\.1\.3\.0$ ]] || [[ "$oid" =~ ^iso\.3\.6\.1\.6\.3\.18\.1\.3\.0$ ]]; then
     ```
3. **Uprawnienia pliku pułapek:** w Debianie `snmptrapd` działa jako `Debian-snmp`. Katalog `Debian-snmp:zabbix 0750`, plik `Debian-snmp:zabbix 0640`; w logrotate `su Debian-snmp zabbix` i `create 0640 Debian-snmp zabbix`.
4. **Konfiguracja serwera/proxy Zabbix:**
   ```
   SNMPTrapperFile=/var/log/zabbix-snmptraps/snmptraps.log
   StartSNMPTrapper=1
   ```
5. **Start przy rozruchu:** w Debianie `snmptrapd.service` ma stan `static` i uruchamia go `snmptrapd.socket` dopiero przy pierwszej pułapce. Żeby proces działał od razu po starcie systemu: `sudo systemctl add-wants multi-user.target snmptrapd.service`.
6. **Firewall:** UDP 162 tylko z adresu NAS-a.
7. **QTS:** *Panel sterowania → Usługi sieciowe i plików → SNMP* – *Trap Address 1* = adres serwera/proxy, poziomy pułapek *Warning* i *Error*. QTS wysyła pułapki z tym samym community, którego używa do odpytywania. Pułapki sprawdzono na TVS-473e (QTS 5.2) i TS-251; oba używają tego samego formatu QTS-MIB.

**Test bez NAS-a** (na serwerze/proxy):
```
snmptrap -v1 -c '<twoje_community>' 127.0.0.1 1.3.6.1.4.1.55062.1.12.2 <IP_NAS> 6 2 '' 1.3.6.1.4.1.55062.1.12.1.102.0 s "[Test] Warning trap"
```
Na hoście powinien pojawić się problem *QNAP warning: [Test] Warning trap* z tagiem `qts_module: Test`.

---

## ⚙️ Makra (Macros)

Makra dla wolumenów, pul i interfejsów obsługują kontekst, więc próg dla pojedynczego wolumenu, puli lub portu ustawisz na hoście (np. `{$VFS.FREE.MIN.WARN:"[Volume QTS, Pool 1]"}`, `{$POOL.FREE.MIN.WARN:"2"}` – kontekstem puli jest jej numer z QTS).

| Makro | Wartość domyślna | Opis |
|---|---|---|
| `{$CPU.UTIL.CRIT}` | `90` | Krytyczne obciążenie CPU (%), liczone jako średnia z 10 minut. |
| `{$EXT.FREE.MIN}` | `10` | Próg małej ilości wolnego miejsca na dyskach zewnętrznych USB/eSATA (%). |
| `{$FAN.SPEED.MIN}` | `200` | Minimalna prędkość wentylatora (RPM); poniżej wentylator jest traktowany jako zatrzymany. |
| `{$MEMORY.UTIL.MAX}` | `90` | Próg wykorzystania pamięci (%) bez cache i buforów, jako minimum z 5 minut. |
| `{$NET.IF.CONTROL}` | `1` | Alarm, gdy interfejs przestaje działać: 1 = tak, 0 = nie. Kontekst dla interfejsu, np. `{$NET.IF.CONTROL:"eth3"}` = 0 dla portu celowo niepodłączonego. |
| `{$NET.IF.ERRORS.WARN}` | `2` | Próg błędów pakietów na interfejsie (błędy/s), wejście lub wyjście, jako minimum z 5 minut. Kontekst dla interfejsu. |
| `{$NET.IF.IFNAME.MATCHES}` | `^eth[0-3]$` | Wyrażenie regularne dla fizycznych interfejsów sieciowych do odkrycia. |
| `{$NET.IF.IFNAME.NOT_MATCHES}` | `(veth\|vnet\|docker\|lo\|lxc\|qvs\|dummy\|tun)` | Wyrażenie regularne wykluczające interfejsy wirtualne z odkrywania. |
| `{$NET.IF.UTIL.MAX}` | `80` | Próg wykorzystania interfejsu (%), wejście lub wyjście, jako minimum z 10 minut. |
| `{$POOL.FREE.MIN.CRIT}` | `10` | Krytycznie mało wolnego miejsca w puli pamięci (%). |
| `{$POOL.FREE.MIN.WARN}` | `20` | Mało wolnego miejsca w puli pamięci (%). |
| `{$POOL.FULL.DAYS.WARN}` | `30` | Ostrzeżenie, gdy według prognozy pula zapełni się w ciągu tylu dni (trend z ostatnich 7 dni). Kontekst dla puli. |
| `{$QNAP.DRIVE.ENC.EXCLUDE}` | `^33$` | Wyrażenie regularne ID jednostek QNAP pomijanych przez *Physical Drive Discovery* (33 = USB w QTS 5.2). |
| `{$QNAP.WEB.PORT}` | `8080` | Port TCP interfejsu WWW QTS, używany do sprawdzenia usługi i w linku *Open QTS*. |
| `{$QNAP.WEB.SCHEME}` | `http` | Protokół interfejsu WWW QTS (`http` albo `https`), używany w linku *Open QTS*. |
| `{$TEMP.CPU.CRIT}` | `85` | Krytyczna temperatura CPU (°C). |
| `{$TEMP.DISK.CRIT}` | `60` | Krytyczna temperatura dysku (°C). |
| `{$TEMP.DISK.WARN}` | `50` | Ostrzegawcza temperatura dysku (°C). |
| `{$TEMP.SYSTEM.CRIT}` | `65` | Krytyczna temperatura systemu (płyty głównej) (°C). |
| `{$VFS.FREE.MIN.CRIT}` | `10` | Krytycznie mało wolnego miejsca na wolumenie (%). |
| `{$VFS.FREE.MIN.WARN}` | `20` | Mało wolnego miejsca na wolumenie (%). |
| `{$VFS.FULL.DAYS.WARN}` | `30` | Ostrzeżenie, gdy według prognozy wolumen zapełni się w ciągu tylu dni (trend z ostatnich 7 dni). Kontekst dla wolumenu. |

**Community SNMP:** nie trzymaj go w szablonie. W interfejsie SNMP hosta ustaw community na `{$SNMP_COMMUNITY}`, a makro zdefiniuj na hoście jako *Secret text*. Nie używaj `public`.

---

## 🔍 Reguły Low-Level Discovery (LLD)

* **Ethernet Interface Discovery**: ruch In/Out, prędkość (`ifHighSpeed`), błędy, odrzucenia i stan operacyjny (interfejsy wirtualne odfiltrowane); próg błędów i *Interface is down* sterowane makrami dla każdego portu.
* **System Component Discovery**: temperatury jednostki głównej i jednostek rozszerzających. *Override LLD nie tworzy itemu ani triggerów temperatury dla kart QM2 PCIe (raportują `-100`).*
* **CPU Core Discovery**: obciążenie każdego rdzenia.
* **Disk Performance Discovery**: IOPS i opóźnienie dla każdego wolumenu logicznego.
* **Physical Drive Discovery**: temperatury, pojemność, kody i statusy SMART, numer seryjny dysków wewnętrznych (HDD/SSD, NVMe na kartach QM2); dyski USB są pomijane (`{$QNAP.DRIVE.ENC.EXCLUDE}`), więc nie mają itemu numeru seryjnego; triggery temperatur z histerezą 5 °C.
* **External Drive Discovery (USB/eSATA)**: status, rozmiar i wolne miejsce w dokładnych bajtach (tabela wolumenów QTS-MIB, ten sam indeks co starsza tabela – sprawdzone 27.11.2026 z dyskiem USB); nazwy pokazują etykietę wolumenu i port USB, np. `USB drive BACKUP (port 4): Free space`.
* **Fan Discovery**: prędkość (RPM) i status kontrolera wentylatora.
* **Storage Pool Discovery**: pojemność, wolne miejsce i zajętość każdej puli pamięci (QTS-MIB), triggery małej ilości wolnego miejsca i prognoza zapełnienia.
* **RAID Group Discovery**: status macierzy (stany QTS zamienione na kody liczbowe), pojemność i postęp odbudowy. *Free space* domyślnie wyłączony (QTS raportuje 0).
* **Logical Volume Discovery**: wolne miejsce, rozmiar całkowity (dokładne bajty z tabeli wolumenów QTS-MIB `1.3.6.1.4.1.55062.1.10.9.1`; nazwy ze starszej tabeli, ten sam indeks – sprawdzone 25.11.2026 na 17 wolumenach) i zajętość, status wolumenu (*Status is not Ready*), triggery małej ilości wolnego miejsca i prognoza zapełnienia.

---

## 🚨 Triggery

Wszystkie nazwy triggerów kończą się na `on {HOST.NAME}` (pominięte poniżej). `{volume}` to skrócona nazwa wolumenu, np. `QTS (Pool 1)`. *Open QTS* = link do interfejsu WWW QTS w menu problemu. Triggery *No data* zależą od *Host is unavailable* i *No SNMP data collection*; *Low free space* i *Will be full* zależą od *Critically low free space* tej samej puli lub wolumenu; *Temperature is high* dysku zależy od *Temperature is critical*.

| Źródło | Trigger | Ważność | `scope` | Open QTS | Uwagi |
|---|---|---|---|---|---|
| Template | `Host is unavailable` | Disaster | availability |  |  |
| Template | `SMB service is down` | High | availability |  |  |
| Template | `QTS web interface is down` | Average | availability |  |  |
| Template | `CPU usage data is not responding (No data)` | Average | availability |  |  |
| Template | `High CPU utilization for 10 minutes` | Warning | performance |  |  |
| Template | `QNAP SNMP trap (other)` | Information | health | ✓ |  |
| Template | `QNAP warning` | Warning | health | ✓ |  |
| Template | `QNAP error` | High | health | ✓ |  |
| Template | `CPU temperature is high ({ITEM.VALUE1})` | Warning | health | ✓ |  |
| Template | `CPU temperature sensor is not responding (No data)` | Average | availability |  |  |
| Template | `Firmware version has changed` | Information | audit | ✓ |  |
| Template | `System temperature is high ({ITEM.VALUE1})` | Warning | health |  | wyłączony |
| Template | `System temperature sensor is not responding (No data)` | Average | availability |  |  |
| Template | `System has been restarted` | Warning | availability | ✓ |  |
| Template | `Memory metrics are not responding (No data)` | Average | availability |  |  |
| Template | `High memory utilization (>{$MEMORY.UTIL.MAX}% for 5m)` | Average | performance | ✓ |  |
| Template | `No SNMP data collection` | Average | availability |  |  |
| Ethernet Interface | `{#IFNAME}: Interface speed changed` | Information | performance |  |  |
| Ethernet Interface | `{#IFNAME}: Interface is down` | High | availability |  |  |
| Ethernet Interface | `{#IFNAME}: High bandwidth utilization (>{$NET.IF.UTIL.MAX}%)` | Warning | performance |  |  |
| Ethernet Interface | `{#IFNAME}: High error rate (>{$NET.IF.ERRORS.WARN:"{#IFNAME}"} errors/s for 5m)` | Warning | health |  |  |
| System Component | `{#COMPNAME}: Temperature is high ({ITEM.VALUE1})` | Warning | health | ✓ |  |
| System Component | `{#COMPNAME}: Temperature sensor is not responding (No data)` | Average | availability |  |  |
| Physical Drive | `{#DRIVESLOT}: SMART status is not Good` | High | health | ✓ |  |
| Physical Drive | `{#DRIVESLOT}: SMART status is not responding (No data)` | Average | availability |  |  |
| Physical Drive | `{#DRIVESLOT}: Temperature is critical ({ITEM.VALUE1})` | High | health | ✓ |  |
| Physical Drive | `{#DRIVESLOT}: Temperature is high ({ITEM.VALUE1})` | Warning | health | ✓ |  |
| Physical Drive | `{#DRIVESLOT}: Temperature sensor is not responding (No data)` | Average | availability |  |  |
| External Drive | `USB drive {#EXTLABEL} (port N): Connected` | Information | availability |  | nieodkrywany |
| External Drive | `USB drive {#EXTLABEL} (port N): Status is not Ready` | High | health | ✓ |  |
| External Drive | `USB drive {#EXTLABEL} (port N): Low free space (<{$EXT.FREE.MIN}%)` | Average | capacity | ✓ |  |
| Fan | `Fan {#FANID}: Speed is too low or stopped ({ITEM.VALUE1})` | High | health | ✓ |  |
| Fan | `Fan {#FANID}: Speed sensor is not responding (No data)` | Average | availability |  |  |
| Fan | `Fan {#FANID}: System reports failure` | High | health | ✓ |  |
| Storage Pool | `Pool {#POOLID}: Will be full in less than {$POOL.FULL.DAYS.WARN:"{#POOLID}"} days` | Warning | capacity | ✓ |  |
| Storage Pool | `Pool {#POOLID}: Critically low free space` | High | capacity | ✓ |  |
| Storage Pool | `Pool {#POOLID}: Low free space` | Warning | capacity | ✓ |  |
| RAID Group | `RAID {#RAIDID}: Maintenance or synchronization in progress` | Warning | health | ✓ |  |
| RAID Group | `RAID {#RAIDID}: Status is critical (Degraded/Failed)` | High | health | ✓ |  |
| RAID Group | `RAID {#RAIDID}: Status is not responding (No data)` | Average | availability |  |  |
| Logical Volume | `{volume}: Will be full in less than {$VFS.FULL.DAYS.WARN:"{#VOLUMENAME}"} days` | Warning | capacity | ✓ |  |
| Logical Volume | `{volume}: Status is not Ready` | High | health | ✓ |  |
| Logical Volume | `{volume}: Critically low free space` | High | capacity | ✓ |  |
| Logical Volume | `{volume}: Low free space` | Warning | capacity | ✓ |  |

---

## 📊 Dashboard

Wbudowany, wielostronicowy dashboard (pokaz slajdów można włączyć ręcznie):
* **System Overview:** model, czas pracy, firmware, dostępność Ping/SNMP; wskaźniki CPU, temperatury CPU i systemu, pamięci; rząd stanu pamięci masowej (SMART dysków, grupy RAID, zajętość pul); *Active Alerts* i *QTS events (SNMP traps)* z tagiem `qts_module`.
* **Storage: Physical:** statusy SMART na kafelkach Honeycomb (wszystkie dyski, także M.2 na kartach QM2), wykres temperatur dysków z liniami progów, najgorętsze dyski.
* **Storage: Logical:** status grup RAID i zajętość wolumenów i pul, wolne miejsce każdej puli i każdego wolumenu, wykresy IOPS i opóźnienia.
* **Network & Services:** status interfejsów, lustrzany wykres ruchu (przychodzący nad zerem, wychodzący pod zerem), *Interface Health* (prędkość i błędy każdego portu; żółty przy każdym błędzie, czerwony od 2 błędów/s), dostępność SMB i WWW QTS.
* **Hardware Health:** temperatura CPU i systemu w czasie, obciążenie rdzeni, status i prędkość wentylatorów.

---

## ⚙️ Instalacja i dobre praktyki

1. Pobierz plik `SNMP QNAP TVS-473e.yaml`.
2. W Zabbix 8.0 przejdź do **Data collection → Templates → Import**.
3. Powiąż szablon z hostem QNAP; w QTS włącz SNMPv2c i użyj własnego community (makro hosta `{$SNMP_COMMUNITY}`, *Secret text*).
4. **KRYTYCZNE:** w interfejsie SNMP hosta **odznacz `Use bulk requests`**. Demon SNMP w QTS odrzuca zapytania zbiorcze pod dużym obciążeniem I/O, co daje fałszywe problemy `[no data]`.
5. Ustaw `Timeout` na serwerze/proxy Zabbix na co najmniej `10s`.
6. Opcjonalnie: skonfiguruj odbiornik pułapek (sekcja *Pułapki SNMP*).

---

## ⚠️ Znane problemy

| Objaw | Przyczyna | Obejście |
|---|---|---|
| QTS raportuje dysk NVMe na karcie QM2 jako SAS | Tak QTS raportuje go przez SNMP | Obsłużone: *Drive type* zamienia SAS na NVMe (sprawdzone na WD Red SN700 w QM2-2P-244A, 19.11.2026). Skutek uboczny: prawdziwy dysk SAS też byłby pokazany jako NVMe |
| Pułapki nigdy nie trafiają do pliku, w `journalctl -u snmptrapd` jest *Permission denied* | W Debianie `snmptrapd` działa jako `Debian-snmp`, nie jako root | Właściciel `Debian-snmp:zabbix` pliku pułapek i jego katalogu (patrz *Wymagania*, punkt 3) |
| `snmptrapd` jest `active`, ale w dzienniku jest *no access control information configured … will NOT accept any incoming notifications* | `snmptrapd` nie może odczytać `snmptrapd.conf` (np. `0600 root:root`), więc nie widzi `authCommunity` | `root:Debian-snmp`, `0640` dla `snmptrapd.conf`, restart `snmptrapd` i kontrola dziennika |
| Po restarcie serwera/proxy proces `snmptrapd` nie działa | `snmptrapd.service` ma stan `static`; `snmptrapd.socket` uruchamia go dopiero przy pierwszej pułapce | `sudo systemctl add-wants multi-user.target snmptrapd.service` |
| Pułapki przestają dochodzić po aktualizacji pakietu Zabbix | Skrypt poinstalacyjny pakietu Zabbix przy każdej instalacji i aktualizacji wykonuje `chown -R zabbix:zabbix /var/log/zabbix`, więc `snmptrapd` (`Debian-snmp`) traci prawo zapisu do pliku pułapek | Trzymaj plik pułapek poza `/var/log/zabbix` (np. `/var/log/zabbix-snmptraps/`) |
| Pułapka pojawia się tylko jako `ZBXTRAP 127.0.0.1` / niedopasowana | Handler nie rozpoznaje `iso.3.6.1.6.3.18.1.3.0`, gdy MIB-y nie są wczytane | Użyj rozszerzonego wyrażenia regularnego z sekcji *Pułapki SNMP* |
| `\"` w nazwach problemów | `snmptrapd` poprzedza cudzysłowy w komunikatach QTS ukośnikiem | Kosmetyczne |
| `snmpwalk`/`snmpget` zwraca *Timeout* | Złe community albo wyłączone SNMP w QTS | Porównaj community w QTS z makrem `{$SNMP_COMMUNITY}` na hoście |
| *RAID N: Free space* pokazuje 0 B | QTS raportuje wolne miejsce grupy RAID, która jest w całości oddana puli | Domyślnie wyłączony od 4.0.0; używaj *Pool N: Free space* |
| *Storage Pool Discovery* nic nie wykrywa albo itemy są *Not supported* | Dotąd niespotykane: tabela pul QTS-MIB odpowiada na TVS-473e (QTS 5.2, 24.11.2026) i TS-251 (27.11.2026). Starsza wersja QTS może jej nie mieć | Sprawdź `snmpwalk -v2c -c '<COMMUNITY>' <IP-NAS> 1.3.6.1.4.1.55062.1.10.7.1.2` – musi pokazać pule. Jeśli nie, wyłącz regułę na tym hoście |
| Wolne miejsce puli różni się od wolnego miejsca wolumenu | Pula obejmuje wolumeny, migawki i rezerwę – to dwa różne pomiary | Normalne |
| Kolory dashboardu nie uwzględniają progu zmienionego na hoście (np. `{$TEMP.CPU.CRIT}`) | Progi w widgetach dashboardu są liczbami, nie makrami | Popraw też progi widgetów w dashboardzie szablonu |
| *Will be full in less than N days* nie zgłasza się zaraz po podłączeniu albo zgłasza się po jednorazowym dużym kopiowaniu | `timeleft()` ekstrapoluje trend wolnego miejsca z ostatnich 7 dni | Normalne; zamyka się sam, gdy prognoza przekroczy dwukrotność progu |
| *Open QTS* otwiera zły adres | Link używa `{HOST.CONN}` (adres interfejsu SNMP hosta), `{$QNAP.WEB.SCHEME}` i `{$QNAP.WEB.PORT}` | Ustaw oba makra na hoście; interfejs SNMP musi mieć adres, pod którym QTS jest osiągalny z przeglądarki |
| *Status is not Ready* zgłasza się przy krótkiej operacji (np. sprawdzanie wolumenu) | Zaobserwowano tylko `Ready` (17 wolumenów, 26.11.2026); innych tekstów statusu QTS nie znamy, więc każdy inny tekst otwiera problem | Jeśli to oczekiwane, zamknij ręcznie; zgłoś tekst statusu, żeby go obsłużyć |
| *Memory: Available* ma stan *Not supported* albo pokazuje złą wartość | Dotąd niespotykane: indeks 11 w `hrStorage` to *Available memory* na TVS-473e (QTS 5.2, 26.11.2026) i TS-251 (27.11.2026). Inna wersja QTS lub inny model może nie mieć tego wpisu albo mieć go pod innym indeksem | Sprawdź `snmpget -v2c -c '<COMMUNITY>' <IP-NAS> 1.3.6.1.2.1.25.2.3.1.3.11` – odpowiedź musi brzmieć `"Available memory"`. Jeśli nie, wyłącz na tym hoście *Memory: Available*, *Memory utilization* i *High memory utilization* |
| *Physical Drive Discovery* pokazuje *item prototype with the same key already exists*, gdy podłączony jest dysk USB | 3.x: dysk USB pojawia się w tabeli dysków QTS bez etykiety slotu | Naprawione w 4.0.0 filtrem `{$QNAP.DRIVE.ENC.EXCLUDE}` (`^33$`, jednostka USB w QTS 5.2). Jeśli jednostka USB ma inne ID (QTS-MIB `1.3.6.1.4.1.55062.1.10.34`), zmień makro na hoście |
| Dyski na karcie QM2 mają nazwy `HDD5`, `HDD6`; SSD włożony do wewnętrznego gniazda M.2 może przesunąć etykiety | Etykiety slotów pochodzą ze starszej tabeli slotów NAS-MIB, łączonej z tabelą dysków po indeksie | Po każdej zmianie dysków porównaj *Serial number* z QTS (*Pamięć masowa i migawki → Dyski/VJBOD*) |
| Po odłączeniu dysku USB jego itemy mają stan *Not supported* (*No Such Instance currently exists at this OID*) | Wolumen znika z tabel SNMP; zaobserwowane 27.11.2026 | Oczekiwane. Po najbliższym przebiegu *External Drive Discovery* (do 1h) itemy dostają oznaczenie nieodkrytych i zostają przez 365 dni (`lifetime: 365d`, bez wyłączania), więc historia zostaje. Po ponownym podłączeniu tego samego dysku do tego samego portu (27.11.2026) QTS nadał mu ten sam indeks SNMP i te same itemy zbierały dalej, z ciągłą historią; inny dysk lub port może dostać inny indeks i nowe itemy |
| Nazwa dysku USB pokazuje `()` albo pustą etykietę | Wolumen nie ma etykiety (QTS-MIB kolumna 8) albo nazwa QTS nie ma części `Drive: '…'` | Kosmetyczne; klucze itemów używają indeksu SNMP |

---

## 📝 Historia zmian

Zobacz [CHANGELOG.md](CHANGELOG.md).
