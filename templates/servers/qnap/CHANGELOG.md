# Changelog – SNMP QNAP TVS-473e

---

## 🇬🇧 English Version

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
