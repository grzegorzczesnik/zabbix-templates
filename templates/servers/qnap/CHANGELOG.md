# Changelog – SNMP QNAP TVS-473e

---

## 🇬🇧 English Version

### v4.1.0 – 2026-11-27

**Zabbix Version:** 8.0

Minor release. Nothing from 4.0.0 is renamed or removed; import over 4.0.0 only adds elements and keeps history.

#### ✨ Added

- **Trigger prototype *{volume}: High I/O latency (>{$VOL.LATENCY.WARN:"{#VOLNAME}"} ms for 15m)*** in *Disk Performance Discovery* (Warning, `scope: performance`, *Open QTS* link, operational data *Current*):
  - expression `min(…qnap.disk.latency[{#SNMPINDEX}],15m) > {$VOL.LATENCY.WARN:"{#VOLNAME}"}`;
  - recovery `max(…,15m) < {$VOL.LATENCY.WARN:"{#VOLNAME}"}*0.8`;
  - 17 triggers created on the test NAS (2026-11-27).
- Macro `{$VOL.LATENCY.WARN}` (50 ms) with context per volume; default chosen from 7 days of latency data (2026-11-20 to 2026-11-27: HDD volumes up to 41 ms sustained, single peaks about 65 ms, NVMe below 5 ms).
- **USB Drive Hardware Discovery** (`qnap.usb.drive.discovery`) – USB drives from the QTS drive table (LLD macros `{#USBENC}` from the legacy enclosure column, `{#USBPORT}` from the QTS-MIB slot column; filter `{#USBENC}` matches `{$QNAP.DRIVE.ENC.USB}`; items kept 365 days, never disabled):
  - `USB port N: Serial number` – `qnap.usb.drive.serial[{#SNMPINDEX}]`, QTS-MIB `1.3.6.1.4.1.55062.1.10.2.1.5`, every 1h, discard unchanged 1d;
  - `USB port N: Model` – `qnap.usb.drive.model[{#SNMPINDEX}]`, QTS-MIB `1.3.6.1.4.1.55062.1.10.2.1.4`, interface in brackets removed by regex;
  - verified 2026-11-27 with a Kingston DataTraveler in USB port 4.
- Macro `{$QNAP.DRIVE.ENC.USB}` (`^33$`).

#### 🔧 Changed

- Operational data added: *Interface is down* (`Current state`), *High bandwidth utilization* (`In`, `Out`), *Fan: Speed is too low or stopped* (`Current speed`), *USB drive: Low free space* (`Free` / `Total`).

---

### v4.0.0 – 2026-11-27

**Zabbix Version:** 8.0

Major release. It contains the unpublished work versions 3.1.0–3.4.0 and the changes below. Keys of existing items are unchanged, so history is kept, but trigger names, external drive item names and some `scope` tags changed – read *Upgrade notes (3.0.0 → 4.0.0)* in the README before importing.

#### ✨ Added

- **Storage Pool Discovery** (`qnap.pool.discovery`) – discovers storage pools from the QTS-MIB pool table `1.3.6.1.4.1.55062.1.10.7.1`:
  - `Pool N: Total capacity` – `qnap.pool.total[{#SNMPINDEX}]`, bytes;
  - `Pool N: Free space` – `qnap.pool.free[{#SNMPINDEX}]`, bytes (matches the free pool space shown in QTS Storage & Snapshots);
  - `Pool N: Space utilization` – `qnap.pool.util[{#SNMPINDEX}]`, calculated, %;
  - triggers *Pool N: Low free space* (Warning) and *Pool N: Critically low free space* (High); Warning depends on High.
- Macros `{$POOL.FREE.MIN.WARN}` (20) and `{$POOL.FREE.MIN.CRIT}` (10), with context per pool number.
- **Fill-up forecast** – trigger prototypes *Pool N: Will be full in less than {$POOL.FULL.DAYS.WARN} days* and *{volume}: Will be full in less than {$VFS.FULL.DAYS.WARN} days* (Warning):
  - expression `timeleft(…free…,7d,0) < {$…FULL.DAYS.WARN:"…"}*86400`, recovery when the forecast is longer than twice the threshold;
  - each depends on *Critically low free space* of the same pool or volume.
- Macros `{$POOL.FULL.DAYS.WARN}` (30), `{$VFS.FULL.DAYS.WARN}` (30), `{$NET.IF.ERRORS.WARN}` (2), `{$NET.IF.CONTROL}` (1), `{$QNAP.WEB.SCHEME}` (`http`); the first four support context.
- **Open QTS** menu link (`{$QNAP.WEB.SCHEME}://{HOST.CONN}:{$QNAP.WEB.PORT}/`) in 24 triggers and trigger prototypes (storage, drives, fans, temperatures, traps, firmware, restart). Network and *No data* triggers have no link.
- *System Component Discovery*: override *Watchdog exclusion for QM2 cards* also stops the temperature item for QM2 cards (they report `-100`).
- **Volume status** – item prototype *{volume}: Status* (`qnap.volume.status[{#SNMPINDEX}]`, QTS-MIB `1.3.6.1.4.1.55062.1.10.9.1.5`, text) and trigger prototype *{volume}: Status is not Ready* (High, *Open QTS* link).
- **Memory: Available** (`vm.memory.available`) – HOST-RESOURCES-MIB `hrStorage` *Available memory* (index 11), KB × 1024.
- Trigger **High memory utilization (>{$MEMORY.UTIL.MAX}% for 5m)** (Average), recovery below threshold − 5 %, depends on *Memory metrics are not responding*; macro `{$MEMORY.UTIL.MAX}` (90).
- **Drive serial number** – item prototype *{#DRIVESLOT}: Serial number* (`qnap.drive.serial[{#DRIVESLOT}]`, QTS-MIB `1.3.6.1.4.1.55062.1.10.2.1.5`, every 24h, `scope: inventory`); same index as the QTS drive table (verified 2026-11-27).
- Macro `{$QNAP.DRIVE.ENC.EXCLUDE}` (`^33$`) – QNAP enclosure IDs skipped by *Physical Drive Discovery* (33 = USB).

#### 🔧 Changed

- **Physical Drive Discovery skips USB drives:** a connected USB drive appears in the QTS drive table (enclosure 33, SMART `Abnormal`, no slot label) and the rule failed with *item prototype with the same key already exists* (verified 2026-11-27). New LLD macro `{#DRIVEENC}` (`1.3.6.1.4.1.24681.1.4.1.1.1.1.5.2.1.3`) and filter: `{#DRIVEENC}` does not match `{$QNAP.DRIVE.ENC.EXCLUDE}`, `{#DRIVESLOT}` exists.
- **External drives in exact bytes:** *Free space*, *Total size* and *Status* read the QTS-MIB volume table `1.3.6.1.4.1.55062.1.10.9.1` (columns 4, 3 and 5; sizes KB × 1024) instead of text from `1.3.6.1.4.1.24681.1.2.17.1`; JavaScript preprocessing removed. Same index in both tables (verified 2026-11-27 with an 8 GB USB drive; equal to `hrStorage` to the byte).
- **External drive names:** new LLD macro `{#EXTLABEL}` (volume label, QTS-MIB column 8); items `USB drive {#EXTLABEL} (port N): Free space / Total size / Status`, triggers `…: Connected`, `…: Status is not Ready` (status in operational data), `…: Low free space (<{$EXT.FREE.MIN}%)`. Port taken from the QTS name with `regsub`.
- *SNMP Agent is unreachable* → **No SNMP data collection** (name used in the Zabbix templates); all dependencies updated.
- *Fan N: System reports failure (Error Code: …)* → **Fan N: System reports failure**; status code in operational data, so every problem has the same name.
- *Physical Drive Discovery* description: slot labels verified (2026-11-27: `HDD1`–`HDD4` = 3.5" bays 1–4, `HDD5`–`HDD6` = QM2 M.2 slots).
- **Volumes in exact bytes:** *{volume}: Free space* and *{volume}: Total size* read the QTS-MIB volume table `1.3.6.1.4.1.55062.1.10.9.1` (columns 4 and 3, KB × 1024) instead of parsing text from `1.3.6.1.4.1.24681.1.2.17.1`; JavaScript preprocessing removed. Same index in both tables (verified 2026-11-25 on 17 volumes, max. difference 0.08 %). Volume names still come from the legacy table.
- **High error rate** (*Ethernet Interface Discovery*): fires when inbound or outbound errors stay above `{$NET.IF.ERRORS.WARN}` errors/s for 5 minutes (was: any error in 5 minutes); severity High → **Warning**; recovery below 80 % of the threshold; operational data `In: … , Out: …`.
- **Memory utilization** is calculated from *Memory: Available* (kernel estimate of available memory, as in the Zabbix Linux templates) instead of *Memory: Free* from the QNAP MIB, which is slightly higher than the memory that can really be reclaimed (test NAS 2026-11-26 13:12: Free 13.6 GB, Available 12.7 GB; utilization 55.9 % → 58.8 %). *Memory metrics are not responding* now watches *Memory: Available*.
- *SMB service is down* and *QTS web interface is down* depend only on *Host is unavailable* (was also *SNMP Agent is unreachable*, now *No SNMP data collection*, which hid TCP check alerts when only the QTS SNMP service hung).
- *Fan N: Speed is too low or stopped* depends on *Fan N: System reports failure*.
- *High bandwidth utilization*: recovery below `{$NET.IF.UTIL.MAX}` − 10 (was a fixed 70 %).
- *High CPU utilization*: operational data `Current: …`.
- Sentence case in item and trigger names, e.g. *ICMP ping*, *Service status: SMB (file sharing)*, *SMART status code*, *Is global spare*, *Fan N: Status code*, *RAID N: Total capacity*, *SMB service is down*, *QTS web interface is down*, *CPU usage data is not responding*. Keys unchanged.
- JavaScript preprocessing (SMART status text, RAID status): comments and error message in English.
- **Interface is down:** fires only when `{$NET.IF.CONTROL:"{#IFNAME}"}` = 1.
- **Drive temperature triggers:** 5 °C hysteresis (recovery expressions).
- **Trigger names** – all end with `on {HOST.NAME}`; renamed: *Host is unavailable*, *System has been restarted*, *Interface speed changed*, *High bandwidth utilization*, *High error rate*, *Drive Health is NOT Good* → *SMART status is not Good*, *Temperature is critical/high* (bracket position).
- Operational data: *Interface speed changed* `Current: …`, *SMART status is not Good* `Status: …`, volume *Low free space* `Free: … / Total: …`.
- Tag `scope`: `health` → `availability` in the *No data* triggers of system components, SMART status, fan speed and RAID status.
- *Drive temperature No data* trigger: `on {HOST.NAME}` and *Allow manual close* like the other *No data* triggers.
- RAID item and trigger names unified to `RAID N: …`.
- *Is Global Spare*: update interval 1h with *Discard unchanged with heartbeat*.
- Item prototype **RAID N: Free Space** is created disabled; its description explains why (QTS reports 0 – the whole RAID group is allocated to a pool).
- Descriptions of the template and of *RAID Group Discovery* updated (RAID groups are no longer called storage pools).

#### 📊 Dashboard

- *System Overview*: problem list **QTS events (SNMP traps)** – problems with the `qts_module` tag, all severities including Information, `qts_module` shown first.
- *Storage: Logical*: **Free Space** honeycomb – free space per volume with the short volume names.
- *Hardware Health*: **Temperatures** graph – CPU and system temperature over time with trigger lines.
- *Active Alerts* hides problems with the `qts_module` tag, so trap events are not shown twice.
- *Network & Services*: the separate *Inbound* and *Outbound* graphs are merged into one **Network Traffic** graph; outbound is drawn below zero with the Zabbix 8.0 data set option *Invert values*.
- *Storage: Logical*: widget heights aligned.
- Slideshow no longer starts automatically.
- *Storage: Logical*: **Pool Free Space** honeycomb.
- *Space Utilization (%)* also lists pools (pattern `*: Space utilization`).
- *System Overview*: storage health row – honeycombs **Disk SMART Status**, **RAID Groups Status** and **Pools** (pool utilization, yellow from 80 %, red from 90 %, matching `{$POOL.FREE.MIN.WARN}`/`{$POOL.FREE.MIN.CRIT}`).
- *Network & Services*: **Interface Health** list – negotiated speed and inbound/outbound errors per port.
- *Disk SMART Status*: value `-1` (Error) is red instead of grey.
- *RAID Groups Status*: value `0` (Unknown/Error) is red instead of grey.
- Gauge *CPU Temperature*: yellow from 75 °C, red from 85 °C (was 60/80), matching `{$TEMP.CPU.CRIT}`.
- Gauge *System Temp*: yellow from 60 °C, red from 65 °C (was 65/85), matching `{$TEMP.SYSTEM.CRIT}`.
- *Hottest Drives*: yellow from 50 °C, red from 60 °C (was 45/60/75), matching `{$TEMP.DISK.WARN}`/`{$TEMP.DISK.CRIT}`.
- One colour palette on all pages; *Hardware Health* (fans, CPU cores) used different shades.
- *Storage: Logical* reordered: RAID status and utilization, then pool and volume free space, then IOPS and latency.
- *Interface Health*: errors green at 0, yellow above 0, red from 2 errors/s (matching `{$NET.IF.ERRORS.WARN}`).

#### 🗑 Removed

- Graph prototype with a pie chart of a single drive temperature (*Physical Drive Discovery*).
- *Hardware Health*: *CPU Temperature* and *System Temp* gauges (they duplicated the gauges on *System Overview*).

---

### v3.0.0 – 2026-11-24

**Zabbix Version:** 8.0

Major release: SNMP trap support for QTS events, consistent naming, tagging and bilingual documentation, fewer false and duplicate alerts, and all hard-coded thresholds moved to macros. The export format is now Zabbix 8.0, so the template no longer imports into 7.4. Item keys are unchanged, so history is kept when you update an existing host – see *Upgrade notes* in the README.

#### ⚠️ Breaking

- **Requires Zabbix 8.0+** (export format `8.0`; it cannot be imported into Zabbix 7.4).
- **SNMP traps need a receiver** on the Zabbix server or proxy: `snmptrapd` with `zabbix_trap_handler.sh`, `SNMPTrapperFile` and `StartSNMPTrapper=1` – see the README. Without it the trap items simply stay empty.

#### ✨ Added

- **SNMP traps (QTS-MIB, enterprise 55062)**, split by QTS event level:
  - `System: Last SNMP trap (Error)` – `snmptrap["55062\.1\.12\.2\.0\.4\b"]`, trigger *QNAP error* (High);
  - `System: Last SNMP trap (Warning)` – `snmptrap["55062\.1\.12\.2\.0\.2\b"]`, trigger *QNAP warning* (Warning);
  - `System: Last SNMP trap (other)` – `snmptrap.fallback`, trigger *QNAP SNMP trap (other)* (Information).
  - The QTS message text is shown in the problem name, and the QTS module (e.g. `Security Center`, `Storage & Snapshots`) is extracted into the `qts_module` tag.
  - Trap triggers use *Multiple* problem generation and no recovery – every QTS event is its own problem and is closed manually.
- **Macros:** `{$NET.IF.UTIL.MAX}` (80), `{$FAN.SPEED.MIN}` (200), `{$EXT.FREE.MIN}` (10) – they replace hard-coded thresholds.
- **Documentation:** template description; EN/PL descriptions on all items, triggers, discovery rules and macros (10 items had none).

#### 🐞 Fixed

- **RAID status:** the JavaScript mapping also accepts `Initializing` (previously only `Initialing`); an unknown spelling produced `0` and a false *Critical* problem.
- Value map `QNAP RAID Status`: label `7 → Initialing` corrected to `Initializing`.
- **Interface speed** read from `ifHighSpeed` (×1 000 000) instead of the 32-bit `ifSpeed`, which caps at 4.29 Gbps.
- **Volume size parsing** (*Free space*, *Total size*): the result is rounded to whole bytes and a non-numeric value raises an error instead of storing `NaN`.
- **USB drive capacity** items had no unit – now `B`.
- Trigger names: missing parenthesis in *Temperature is high* and *CPU temperature is high*, stray space in *Fan … Speed is too low*.

#### 🔧 Changed

- **Interface is down:** fires on a change to a non-up state (instead of only after `Up` in the previous value) and closes when the port is `Up` again (recovery expression).
- **Volume names** shortened in item, trigger and graph names: `[Volume QTS, Pool 1]` → `QTS (Pool 1)`. Context macros still use the full name (`{$VFS.FREE.MIN.WARN:"[Volume QTS, Pool 1]"}`).
- **Polling intervals:** temperatures (drives, components) 5m → 10m; volume capacity 15m → 30m; volume IOPS and latency set explicitly to 5m.
- `{$NET.IF.IFNAME.MATCHES}`: `^eth[0-3]+$` → `^eth[0-3]$` (the four onboard ports; same result on TVS-473e, clearer intent).
- **Tags:** every item, trigger and prototype carries `component` + `scope`; `cause` tag added where relevant.
- *RAID maintenance or synchronization in progress* no longer depends on the critical RAID trigger.
- Dashboard: slideshow starts automatically.

#### 🗑 Removed / disabled

- *System temperature is high* – disabled by default; the same alert comes from System Component Discovery for the main unit.
- *External Drive Connected* – trigger prototype not discovered by default (it was a permanently open Information problem).
- Unused value map `QNAP PSU Status` (TVS-473e does not report a PSU over SNMP).

---

### v2.0.1 – 2026-05-16

#### 🐛 Bug Fixes

- **Value map `QNAP RAID Status`:** Added missing entry `11 → Failed`. Previously, when a RAID array entered the critical Failed state, Zabbix displayed a raw numeric value instead of a human-readable label.
- **Trigger `SMB Service is Down on {HOST.NAME}`:** Added missing `opdata` and `description` fields with a diagnostic instruction. This trigger was the only one in the template lacking these fields.

#### 📝 Improved Item Descriptions

- **`{#DRIVESLOT}: SMART Status Code`** — Replaced placeholder `ok` with a proper bilingual description explaining the numeric code logic and the relationship with the SMART Status Text item.
- **`{#VOLUMENAME}: Free space`** — Replaced placeholder `un` with a bilingual description documenting the JavaScript preprocessing and the purpose of the item.
- **`{#VOLUMENAME}: Total size`** — Replaced placeholder `un` with a bilingual description documenting the JavaScript preprocessing and the purpose of the item.

---

### v2.0.0

**Zabbix Version:** 7.4

Version 2.0.0 is a major overhaul of the alerting logic and polling performance. The main goal was to eliminate false positives and make the template truly production-ready by addressing the quirks of the QTS SNMP agent.

#### 🛠️ Fixes & Optimizations

- **Database Throttling:** Added `Discard unchanged with heartbeat` (from 1h to 24h) to all static inventory items. This significantly reduces DB I/O for data that rarely changes (like model names or serial numbers).
- **Polling Rate Tuning:** Item intervals were adjusted to prevent choking the QTS `snmpd` daemon under heavy load. Critical metrics (Network, CPU) are polled every 1m, hardware health (Disks, Fans, RAID) every 5m, and capacity metrics every 15m.
- **Negative Error Code Support:** Changed LLD data types for Fans and SMART codes from `Unsigned` to `Numeric (float)`. QNAP uses `-1` to report hardware failures, which previously caused items to become "Not Supported".

#### 🧠 Advanced Logic (JavaScript Preprocessing)

- **Multi-State RAID Parser:** RAID statuses are now handled by a custom JS script that maps 11 native QTS textual states into strict numeric values. This allows Zabbix to distinguish between a failure (e.g., Degraded) and standard maintenance (e.g., Rebuilding).
- **USB Drive Parser:** QNAP reports USB drive capacity as a string (e.g., "1.50 TB"). A JS script now parses these strings into raw bytes on the fly, allowing capacity triggers to work correctly.

#### 🛡️ Alert Fatigue Reduction

- **Service Dependency Tree:** Network/Agent failures now suppress child alerts. If Ping or SNMP goes down, alerts for SMB, QTS Web, or `nodata` triggers are automatically hidden.
- **Network Hysteresis:** The `Interface is down` trigger now only reacts to ports that were previously `Up` (`last(#2)=1`). Empty switch ports no longer generate false alarms.
- **Performance Spike Filtering:** Network bandwidth (`>80%`) and CPU utilization (`>90%`) triggers now use `min(10m)` and `avg(10m)` functions to ignore short spikes and only alert on sustained loads.

---

## 🇵🇱 Polska Wersja

### v4.1.0 – 27.11.2026

**Wersja Zabbix:** 8.0

Wydanie pomocnicze. Nic z 4.0.0 nie zmienia nazwy ani nie jest usuwane; import na 4.0.0 tylko dodaje elementy i zachowuje historię.

#### ✨ Dodano

- **Prototyp triggera *{wolumen}: High I/O latency (>{$VOL.LATENCY.WARN:"{#VOLNAME}"} ms for 15m)*** w *Disk Performance Discovery* (Warning, `scope: performance`, link *Open QTS*, operational data *Current*):
  - wyrażenie `min(…qnap.disk.latency[{#SNMPINDEX}],15m) > {$VOL.LATENCY.WARN:"{#VOLNAME}"}`;
  - odzyskanie `max(…,15m) < {$VOL.LATENCY.WARN:"{#VOLNAME}"}*0.8`;
  - na testowym NAS-ie powstało 17 triggerów (27.11.2026).
- Makro `{$VOL.LATENCY.WARN}` (50 ms) z kontekstem dla wolumenu; wartość dobrana na podstawie 7 dni danych (20–27.11.2026: wolumeny HDD do 41 ms w sposób ciągły, pojedyncze skoki ok. 65 ms, NVMe poniżej 5 ms).
- **USB Drive Hardware Discovery** (`qnap.usb.drive.discovery`) – dyski USB z tabeli dysków QTS (makra LLD `{#USBENC}` ze starszej kolumny jednostki, `{#USBPORT}` z kolumny slotu QTS-MIB; filtr `{#USBENC}` pasuje do `{$QNAP.DRIVE.ENC.USB}`; itemy trzymane 365 dni, bez wyłączania):
  - `USB port N: Serial number` – `qnap.usb.drive.serial[{#SNMPINDEX}]`, QTS-MIB `1.3.6.1.4.1.55062.1.10.2.1.5`, co 1h, discard unchanged 1d;
  - `USB port N: Model` – `qnap.usb.drive.model[{#SNMPINDEX}]`, QTS-MIB `1.3.6.1.4.1.55062.1.10.2.1.4`, interfejs w nawiasie usuwany wyrażeniem regularnym;
  - sprawdzone 27.11.2026 z pendrive'em Kingston DataTraveler w porcie USB 4.
- Makro `{$QNAP.DRIVE.ENC.USB}` (`^33$`).

#### 🔧 Zmieniono

- Dodane operational data: *Interface is down* (`Current state`), *High bandwidth utilization* (`In`, `Out`), *Fan: Speed is too low or stopped* (`Current speed`), *USB drive: Low free space* (`Free` / `Total`).

---

### v4.0.0 – 27.11.2026

**Wersja Zabbix:** 8.0

Wydanie główne. Zawiera nieopublikowane wersje robocze 3.1.0–3.4.0 oraz poniższe zmiany. Klucze istniejących itemów bez zmian, więc historia zostaje, ale zmieniły się nazwy triggerów, nazwy itemów dysków zewnętrznych i część tagów `scope` – przed importem przeczytaj w README *Uwagi do aktualizacji (3.0.0 → 4.0.0)*.

#### ✨ Dodano

- **Storage Pool Discovery** (`qnap.pool.discovery`) – wykrywa pule pamięci z tabeli pul QTS-MIB `1.3.6.1.4.1.55062.1.10.7.1`:
  - `Pool N: Total capacity` – `qnap.pool.total[{#SNMPINDEX}]`, bajty;
  - `Pool N: Free space` – `qnap.pool.free[{#SNMPINDEX}]`, bajty (zgodne z wolnym miejscem puli w QTS, Pamięć masowa i migawki);
  - `Pool N: Space utilization` – `qnap.pool.util[{#SNMPINDEX}]`, wyliczany, %;
  - triggery *Pool N: Low free space* (Warning) i *Pool N: Critically low free space* (High); Warning zależy od High.
- Makra `{$POOL.FREE.MIN.WARN}` (20) i `{$POOL.FREE.MIN.CRIT}` (10), z kontekstem – numerem puli.
- **Prognoza zapełnienia** – prototypy triggerów *Pool N: Will be full in less than {$POOL.FULL.DAYS.WARN} days* i *{volume}: Will be full in less than {$VFS.FULL.DAYS.WARN} days* (Warning):
  - wyrażenie `timeleft(…free…,7d,0) < {$…FULL.DAYS.WARN:"…"}*86400`, zamknięcie, gdy prognoza przekroczy dwukrotność progu;
  - każdy zależy od *Critically low free space* tej samej puli lub wolumenu.
- Makra `{$POOL.FULL.DAYS.WARN}` (30), `{$VFS.FULL.DAYS.WARN}` (30), `{$NET.IF.ERRORS.WARN}` (2), `{$NET.IF.CONTROL}` (1), `{$QNAP.WEB.SCHEME}` (`http`); pierwsze cztery obsługują kontekst.
- Link **Open QTS** w menu problemu (`{$QNAP.WEB.SCHEME}://{HOST.CONN}:{$QNAP.WEB.PORT}/`) w 24 triggerach i prototypach (pamięć masowa, dyski, wentylatory, temperatury, pułapki, firmware, restart). Triggery sieciowe i *No data* nie mają linku.
- *System Component Discovery*: override *Watchdog exclusion for QM2 cards* nie tworzy też itemu temperatury dla kart QM2 (raportują `-100`).
- **Status wolumenu** – prototyp itemu *{volume}: Status* (`qnap.volume.status[{#SNMPINDEX}]`, QTS-MIB `1.3.6.1.4.1.55062.1.10.9.1.5`, tekst) i prototyp triggera *{volume}: Status is not Ready* (High, link *Open QTS*).
- **Memory: Available** (`vm.memory.available`) – HOST-RESOURCES-MIB `hrStorage` *Available memory* (indeks 11), KB × 1024.
- Trigger **High memory utilization (>{$MEMORY.UTIL.MAX}% for 5m)** (Average), zamknięcie poniżej progu − 5 %, zależy od *Memory metrics are not responding*; makro `{$MEMORY.UTIL.MAX}` (90).
- **Numer seryjny dysku** – prototyp itemu *{#DRIVESLOT}: Serial number* (`qnap.drive.serial[{#DRIVESLOT}]`, QTS-MIB `1.3.6.1.4.1.55062.1.10.2.1.5`, co 24h, `scope: inventory`); ten sam indeks co tabela dysków QTS (sprawdzone 27.11.2026).
- Makro `{$QNAP.DRIVE.ENC.EXCLUDE}` (`^33$`) – ID jednostek QNAP pomijanych przez *Physical Drive Discovery* (33 = USB).

#### 🔧 Zmieniono

- **Physical Drive Discovery pomija dyski USB:** podłączony dysk USB pojawia się w tabeli dysków QTS (jednostka 33, SMART `Abnormal`, bez etykiety slotu), a reguła kończyła się błędem *item prototype with the same key already exists* (sprawdzone 27.11.2026). Nowe makro LLD `{#DRIVEENC}` (`1.3.6.1.4.1.24681.1.4.1.1.1.1.5.2.1.3`) i filtr: `{#DRIVEENC}` nie pasuje do `{$QNAP.DRIVE.ENC.EXCLUDE}`, `{#DRIVESLOT}` istnieje.
- **Dyski zewnętrzne w dokładnych bajtach:** *Free space*, *Total size* i *Status* czytają tabelę wolumenów QTS-MIB `1.3.6.1.4.1.55062.1.10.9.1` (kolumny 4, 3 i 5; rozmiary KB × 1024) zamiast tekstu z `1.3.6.1.4.1.24681.1.2.17.1`; preprocessing JavaScript usunięty. Ten sam indeks w obu tabelach (sprawdzone 27.11.2026 z pendrive'em 8 GB; zgodne co do bajta z `hrStorage`).
- **Nazwy dysków zewnętrznych:** nowe makro LLD `{#EXTLABEL}` (etykieta wolumenu, kolumna 8 QTS-MIB); itemy `USB drive {#EXTLABEL} (port N): Free space / Total size / Status`, triggery `…: Connected`, `…: Status is not Ready` (status w operational data), `…: Low free space (<{$EXT.FREE.MIN}%)`. Port wyciągany z nazwy QTS przez `regsub`.
- *SNMP Agent is unreachable* → **No SNMP data collection** (nazwa z szablonów Zabbix); wszystkie zależności zaktualizowane.
- *Fan N: System reports failure (Error Code: …)* → **Fan N: System reports failure**; kod statusu w operational data, więc każdy problem ma tę samą nazwę.
- Opis *Physical Drive Discovery*: etykiety slotów sprawdzone (27.11.2026: `HDD1`–`HDD4` = zatoki 3.5" 1–4, `HDD5`–`HDD6` = gniazda M.2 karty QM2).
- **Wolumeny w dokładnych bajtach:** *{volume}: Free space* i *{volume}: Total size* czytają tabelę wolumenów QTS-MIB `1.3.6.1.4.1.55062.1.10.9.1` (kolumny 4 i 3, KB × 1024) zamiast parsować tekst z `1.3.6.1.4.1.24681.1.2.17.1`; preprocessing JavaScript usunięty. Ten sam indeks w obu tabelach (sprawdzone 25.11.2026 na 17 wolumenach, maks. różnica 0,08 %). Nazwy wolumenów nadal ze starszej tabeli.
- **High error rate** (*Ethernet Interface Discovery*): zgłasza się, gdy błędy przychodzące lub wychodzące przekraczają `{$NET.IF.ERRORS.WARN}` błędów/s przez 5 minut (było: każdy błąd w 5 minutach); ważność High → **Warning**; zamknięcie poniżej 80 % progu; operational data `In: … , Out: …`.
- **Memory utilization** liczone z *Memory: Available* (szacunek jądra o dostępnej pamięci, jak w szablonach Zabbix dla Linuksa) zamiast z *Memory: Free* z MIB QNAP, które jest nieco wyższe niż pamięć, którą da się naprawdę zwolnić (testowy NAS 26.11.2026 13:12: Free 13,6 GB, Available 12,7 GB; wykorzystanie 55,9 % → 58,8 %). *Memory metrics are not responding* pilnuje teraz *Memory: Available*.
- *SMB service is down* i *QTS web interface is down* zależą tylko od *Host is unavailable* (wcześniej także od *SNMP Agent is unreachable*, obecnie *No SNMP data collection*, co ukrywało alarmy testów TCP, gdy zawiesiła się tylko usługa SNMP w QTS).
- *Fan N: Speed is too low or stopped* zależy od *Fan N: System reports failure*.
- *High bandwidth utilization*: zamknięcie poniżej `{$NET.IF.UTIL.MAX}` − 10 (było na sztywno 70 %).
- *High CPU utilization*: operational data `Current: …`.
- Małe litery w środku nazw itemów i triggerów, np. *ICMP ping*, *Service status: SMB (file sharing)*, *SMART status code*, *Is global spare*, *Fan N: Status code*, *RAID N: Total capacity*, *SMB service is down*, *QTS web interface is down*, *CPU usage data is not responding*. Klucze bez zmian.
- Preprocessing JavaScript (tekst statusu SMART, status RAID): komentarze i komunikat błędu po angielsku.
- **Interface is down:** zgłasza się tylko, gdy `{$NET.IF.CONTROL:"{#IFNAME}"}` = 1.
- **Triggery temperatury dysków:** histereza 5 °C (wyrażenia przywrócenia).
- **Nazwy triggerów** – wszystkie kończą się na `on {HOST.NAME}`; zmienione: *Host is unavailable*, *System has been restarted*, *Interface speed changed*, *High bandwidth utilization*, *High error rate*, *Drive Health is NOT Good* → *SMART status is not Good*, *Temperature is critical/high* (miejsce nawiasu).
- Operational data: *Interface speed changed* `Current: …`, *SMART status is not Good* `Status: …`, *Low free space* wolumenu `Free: … / Total: …`.
- Tag `scope`: `health` → `availability` w triggerach *No data* komponentów systemu, statusu SMART, prędkości wentylatora i statusu RAID.
- Trigger *No data* temperatury dysku: `on {HOST.NAME}` i *Allow manual close* jak w pozostałych triggerach *No data*.
- Nazwy itemów i triggerów RAID ujednolicone do `RAID N: …`.
- *Is Global Spare*: interwał 1h z *Discard unchanged with heartbeat*.
- Prototyp itemu **RAID N: Free Space** tworzy się wyłączony; opis wyjaśnia dlaczego (QTS raportuje 0 – cała grupa RAID jest oddana puli).
- Zaktualizowane opisy szablonu i reguły *RAID Group Discovery* (grupy RAID nie są już nazywane pulami).

#### 📊 Dashboard

- *System Overview*: lista problemów **QTS events (SNMP traps)** – problemy z tagiem `qts_module`, wszystkie poziomy ważności łącznie z Information, `qts_module` na pierwszym miejscu.
- *Storage: Logical*: kafelki **Free Space** – wolne miejsce każdego wolumenu z krótkimi nazwami wolumenów.
- *Hardware Health*: wykres **Temperatures** – temperatura CPU i systemu w czasie z liniami progów triggerów.
- *Active Alerts* ukrywa problemy z tagiem `qts_module`, żeby zdarzenia z pułapek nie wyświetlały się dwa razy.
- *Network & Services*: osobne wykresy *Inbound* i *Outbound* połączone w jeden wykres **Network Traffic**; ruch wychodzący rysowany pod zerem dzięki opcji zbioru danych *Invert values* z Zabbix 8.0.
- *Storage: Logical*: wyrównane wysokości widgetów.
- Pokaz slajdów nie startuje już automatycznie.
- *Storage: Logical*: kafelki **Pool Free Space**.
- *Space Utilization (%)* pokazuje też pule (wzorzec `*: Space utilization`).
- *System Overview*: rząd stanu pamięci masowej – kafelki **Disk SMART Status**, **RAID Groups Status** i **Pools** (zajętość pul, żółty od 80 %, czerwony od 90 %, zgodnie z `{$POOL.FREE.MIN.WARN}`/`{$POOL.FREE.MIN.CRIT}`).
- *Network & Services*: lista **Interface Health** – wynegocjowana prędkość oraz błędy przychodzące i wychodzące każdego portu.
- *Disk SMART Status*: wartość `-1` (Error) jest czerwona zamiast szarej.
- *RAID Groups Status*: wartość `0` (Unknown/Error) jest czerwona zamiast szarej.
- Wskaźnik *CPU Temperature*: żółty od 75 °C, czerwony od 85 °C (było 60/80), zgodnie z `{$TEMP.CPU.CRIT}`.
- Wskaźnik *System Temp*: żółty od 60 °C, czerwony od 65 °C (było 65/85), zgodnie z `{$TEMP.SYSTEM.CRIT}`.
- *Hottest Drives*: żółty od 50 °C, czerwony od 60 °C (było 45/60/75), zgodnie z `{$TEMP.DISK.WARN}`/`{$TEMP.DISK.CRIT}`.
- Jedna paleta kolorów na wszystkich stronach; *Hardware Health* (wentylatory, rdzenie CPU) miała inne odcienie.
- Nowa kolejność strony *Storage: Logical*: stan RAID i zajętość, potem wolne miejsce pul i wolumenów, na końcu IOPS i opóźnienie.
- *Interface Health*: błędy zielone przy 0, żółte powyżej 0, czerwone od 2 błędów/s (zgodnie z `{$NET.IF.ERRORS.WARN}`).

#### 🗑 Usunięto

- Prototyp wykresu kołowego z temperaturą jednego dysku (*Physical Drive Discovery*).
- *Hardware Health*: wskaźniki *CPU Temperature* i *System Temp* (dublowały wskaźniki ze strony *System Overview*).

---

### v3.0.0 – 24.11.2026

**Wersja Zabbix:** 8.0

Wydanie główne: obsługa pułapek SNMP ze zdarzeniami QTS, spójne nazwy, tagi i dwujęzyczna dokumentacja, mniej fałszywych i zdublowanych alarmów, a wszystkie progi wpisane na sztywno przeniesione do makr. Format eksportu to teraz Zabbix 8.0, więc szablonu nie da się już zaimportować do 7.4. Klucze itemów się nie zmieniły, więc przy aktualizacji istniejącego hosta historia zostaje – zobacz *Uwagi do aktualizacji* w README.

#### ⚠️ Zmiany łamiące zgodność

- **Wymagany Zabbix 8.0+** (format eksportu `8.0`; nie da się go zaimportować do Zabbix 7.4).
- **Pułapki SNMP wymagają odbiornika** na serwerze lub proxy Zabbix: `snmptrapd` z `zabbix_trap_handler.sh`, `SNMPTrapperFile` i `StartSNMPTrapper=1` – zobacz README. Bez niego itemy pułapek po prostu pozostają puste.

#### ✨ Dodano

- **Pułapki SNMP (QTS-MIB, enterprise 55062)** z podziałem na poziomy zdarzeń QTS:
  - `System: Last SNMP trap (Error)` – `snmptrap["55062\.1\.12\.2\.0\.4\b"]`, trigger *QNAP error* (High);
  - `System: Last SNMP trap (Warning)` – `snmptrap["55062\.1\.12\.2\.0\.2\b"]`, trigger *QNAP warning* (Warning);
  - `System: Last SNMP trap (other)` – `snmptrap.fallback`, trigger *QNAP SNMP trap (other)* (Information).
  - Treść komunikatu QTS trafia do nazwy problemu, a moduł QTS (np. `Security Center`, `Storage & Snapshots`) do tagu `qts_module`.
  - Triggery pułapek mają generowanie problemów *Multiple* i brak automatycznego zamknięcia – każde zdarzenie QTS to osobny problem zamykany ręcznie.
- **Makra:** `{$NET.IF.UTIL.MAX}` (80), `{$FAN.SPEED.MIN}` (200), `{$EXT.FREE.MIN}` (10) – zastępują progi wpisane na sztywno.
- **Dokumentacja:** opis szablonu; opisy EN/PL we wszystkich itemach, triggerach, regułach odkrywania i makrach (10 itemów nie miało opisu).

#### 🐞 Poprawiono

- **Status RAID:** mapowanie JavaScript przyjmuje też `Initializing` (wcześniej tylko `Initialing`); nieznana pisownia dawała `0` i fałszywy problem *Critical*.
- Mapa wartości `QNAP RAID Status`: etykieta `7 → Initialing` poprawiona na `Initializing`.
- **Prędkość interfejsu** czytana z `ifHighSpeed` (×1 000 000) zamiast 32-bitowego `ifSpeed`, który kończy się na 4,29 Gb/s.
- **Przeliczanie rozmiaru wolumenów** (*Free space*, *Total size*): wynik zaokrąglany do pełnych bajtów, a wartość nieliczbowa zgłasza błąd zamiast zapisywać `NaN`.
- **Pojemność dysków USB** nie miała jednostki – teraz `B`.
- Nazwy triggerów: brakujący nawias w *Temperature is high* i *CPU temperature is high*, zbędna spacja w *Fan … Speed is too low*.

#### 🔧 Zmieniono

- **Interface is down:** reaguje na zmianę stanu na inny niż up (zamiast tylko po `Up` w poprzedniej wartości) i zamyka się, gdy port znów jest `Up` (wyrażenie przywracające).
- **Nazwy wolumenów** skrócone w nazwach itemów, triggerów i wykresów: `[Volume QTS, Pool 1]` → `QTS (Pool 1)`. Makra z kontekstem nadal używają pełnej nazwy (`{$VFS.FREE.MIN.WARN:"[Volume QTS, Pool 1]"}`).
- **Interwały odpytywania:** temperatury (dyski, komponenty) 5m → 10m; pojemność wolumenów 15m → 30m; IOPS i opóźnienie wolumenów ustawione jawnie na 5m.
- `{$NET.IF.IFNAME.MATCHES}`: `^eth[0-3]+$` → `^eth[0-3]$` (cztery wbudowane porty; na TVS-473e ten sam wynik, czytelniejszy zamiar).
- **Tagi:** każdy item, trigger i prototyp ma `component` + `scope`; tam, gdzie ma to sens, dodano tag `cause`.
- *RAID maintenance or synchronization in progress* nie zależy już od krytycznego triggera RAID.
- Dashboard: pokaz slajdów startuje automatycznie.

#### 🗑 Usunięto / wyłączono

- *System temperature is high* – domyślnie wyłączony; ten sam alert daje System Component Discovery dla jednostki głównej.
- *External Drive Connected* – prototyp triggera domyślnie nieodkrywany (był stale otwartym problemem informacyjnym).
- Nieużywana mapa wartości `QNAP PSU Status` (TVS-473e nie raportuje zasilacza przez SNMP).

---

### v2.0.1 – 16.05.2026

#### 🐛 Poprawki błędów

- **Value mapa `QNAP RAID Status`:** Dodano brakujący wpis `11 → Failed`. Wcześniej, gdy macierz RAID wchodziła w stan krytyczny "Failed", Zabbix wyświetlał surową wartość liczbową zamiast czytelnego opisu.
- **Trigger `SMB Service is Down on {HOST.NAME}`:** Dodano brakujące pola `opdata` oraz `description` z instrukcją diagnostyczną. Trigger był jedynym w szablonie bez tych pól.

#### 📝 Poprawiono opisy itemów

- **`{#DRIVESLOT}: SMART Status Code`** — Zastąpiono placeholder `ok` właściwym opisem dwujęzycznym wyjaśniającym logikę kodów numerycznych oraz relację z itemem SMART Status Text.
- **`{#VOLUMENAME}: Free space`** — Zastąpiono placeholder `un` opisem dwujęzycznym dokumentującym preprocessing JavaScript i przeznaczenie itemu.
- **`{#VOLUMENAME}: Total size`** — Zastąpiono placeholder `un` opisem dwujęzycznym dokumentującym preprocessing JavaScript i przeznaczenie itemu.

---

### v2.0.0

**Wersja Zabbix:** 7.4

Wersja 2.0.0 to gruntowna przebudowa logiki alarmowania oraz optymalizacja zapytań SNMP. Głównym celem było wyeliminowanie fałszywych alarmów i dostosowanie szablonu do realiów pracy agenta SNMP w systemach QTS.

#### 🛠️ Poprawki i Optymalizacja

- **Odciążenie bazy danych Zabbix:** Dodano reguły `Discard unchanged with heartbeat` (od 1h do 24h) dla wszystkich statycznych parametrów inwentaryzacyjnych, co znacząco redukuje zapisy do bazy danych.
- **Dostosowanie interwałów (Polling Rate):** Zmieniono czasy odpytywania, aby zapobiec "dławieniu się" demona `snmpd` w QTS pod dużym obciążeniem. Parametry krytyczne (Sieć, CPU) odpytywane są co 1m, sprzęt (Dyski, Wentylatory, RAID) co 5m, a dane pojemnościowe co 15m.
- **Obsługa ujemnych kodów błędów:** Zmieniono typy danych w LLD dla Wentylatorów i SMART z `Unsigned` na `Numeric (float)`. QNAP używa wartości `-1` do raportowania awarii, co wcześniej skutkowało błędem "Not Supported" w Zabbixie.

#### 🧠 Zaawansowana Logika (JavaScript Preprocessing)

- **Wielostanowy Parser RAID:** Statusy RAID są teraz przetwarzane przez autorski skrypt JS, który mapuje 11 natywnych stanów tekstowych z MIB na konkretne wartości liczbowe. Dzięki temu system bezbłędnie odróżnia awarię (np. Degraded) od prac konserwacyjnych (np. Rebuilding).
- **Parser Dysków USB:** QNAP raportuje zajętość dysków USB jako tekst (np. "1.50 TB"). Skrypt JS w locie przelicza te jednostki na bajty, umożliwiając prawidłowe działanie triggerów matematycznych.

#### 🛡️ Redukcja fałszywych alarmów

- **Drzewo Zależności Usług:** Awarie sieci lub agenta SNMP natychmiast ukrywają podrzędne alerty. Brak odpowiedzi na Ping lub błąd SNMP wycisza powiadomienia o niedostępności SMB, WWW czy braku danych z czujników (`nodata`).
- **Histereza Sieciowa:** Trigger `Interface is down` reaguje wyłącznie na porty, które wcześniej były podłączone (`last(#2)=1`). Puste gniazda na switchu nie generują już fałszywych alarmów o utracie połączenia.
- **Filtrowanie skoków wydajności:** Utylizacja pasma sieciowego (`>80%`) oraz procesora (`>90%`) wykorzystuje okna czasowe `min(10m)` i `avg(10m)`. System ignoruje krótkie zatory, alarmując tylko o trwałym przeciążeniu.
