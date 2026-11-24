# Zabbix Template: SNMP QNAP TVS-473e

An optimized, native SNMP template for QNAP NAS devices (tested on TVS-473e and TS-251). Designed for production environments: SNMP polling of system health, storage and network, SNMP traps for QTS events, advanced JavaScript preprocessing, context macros and dependency trees to prevent alert fatigue.

**Template version:** 3.0.0 (Release)  
**Requires:** Zabbix 8.0+  
**Author:** Grzegorz Cześnik (grzegorz@net59.pl)

---

## ✅ What's New in Version 3.0.0 (vs 2.0.1)

* **SNMP traps for QTS events**, split into Error (High), Warning and other (Information). The QTS message is shown in the problem name, and the QTS module (e.g. `Security Center`) goes into the `qts_module` tag.
* **No hard-coded thresholds:** new macros `{$NET.IF.UTIL.MAX}`, `{$FAN.SPEED.MIN}`, `{$EXT.FREE.MIN}`.
* **Fewer false and duplicate alerts:** RAID `Initializing` no longer raises a false Critical, *Interface is down* closes automatically, duplicate system temperature trigger disabled, permanently open *External Drive Connected* problem removed.
* **Consistent naming and documentation:** shortened volume names (`QTS (Pool 1)`), `component` + `scope` tags everywhere, EN/PL descriptions on every object.
* **Zabbix 8.0 export format.**

Full list: [CHANGELOG.md](CHANGELOG.md).

---

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

Volume macros support context, so you can set thresholds for a single volume on the host (e.g. `{$VFS.FREE.MIN.WARN:"[Volume QTS, Pool 1]"}`).

| Macro | Default | Description |
|---|---|---|
| `{$CPU.UTIL.CRIT}` | `90` | Critical CPU utilization (%), checked as the 10-minute average. |
| `{$EXT.FREE.MIN}` | `10` | Low free space threshold for external USB/eSATA drives (%). |
| `{$FAN.SPEED.MIN}` | `200` | Minimum fan speed (RPM); below it the fan is treated as stopped. |
| `{$NET.IF.IFNAME.MATCHES}` | `^eth[0-3]$` | Regular expression for physical network interfaces to discover. |
| `{$NET.IF.IFNAME.NOT_MATCHES}` | `(veth\|vnet\|docker\|lo\|lxc\|qvs\|dummy\|tun)` | Regular expression excluding virtual interfaces from discovery. |
| `{$NET.IF.UTIL.MAX}` | `80` | Interface utilization threshold (%), inbound or outbound, as a 10-minute minimum. |
| `{$QNAP.WEB.PORT}` | `8080` | TCP port of the QTS web interface, used by the service check. |
| `{$TEMP.CPU.CRIT}` | `85` | Critical CPU temperature (°C). |
| `{$TEMP.DISK.CRIT}` | `60` | Critical drive temperature (°C). |
| `{$TEMP.DISK.WARN}` | `50` | Warning drive temperature (°C). |
| `{$TEMP.SYSTEM.CRIT}` | `65` | Critical system (motherboard) temperature (°C). |
| `{$VFS.FREE.MIN.CRIT}` | `10` | Critically low free space on a volume (%). |
| `{$VFS.FREE.MIN.WARN}` | `20` | Low free space on a volume (%). |

**SNMP community:** keep it out of the template. Set the host SNMP interface community to `{$SNMP_COMMUNITY}` and define that macro on the host as *Secret text*. Do not use `public`.

---

## 🔍 Low-Level Discovery (LLD) Rules

* **Ethernet Interface Discovery**: In/Out traffic, speed (`ifHighSpeed`), errors, discards and operational state (virtual interfaces filtered out).
* **System Component Discovery**: Temperatures of the main unit and expansion units. *An LLD override ignores the `-100` temperature reported by QM2 PCIe cards.*
* **CPU Core Discovery**: Utilization per CPU core.
* **Disk Performance Discovery**: IOPS and latency per logical volume.
* **Physical Drive Discovery**: Temperatures, capacity, SMART codes and status for all drives (HDD/SSD/NVMe).
* **External Drive Discovery (USB/eSATA)**: Connection status and capacity.
* **Fan Discovery**: RPM and fan controller status.
* **RAID Group Discovery**: Array status (QTS states mapped to numeric codes), capacity and rebuild progress.
* **Logical Volume Discovery**: Free space, total size and utilization.

---

## 📊 Dashboard

Built-in multi-page dashboard (slideshow starts automatically):
* **System Overview:** Gauges for CPU, memory and system temperature; service availability (Ping/SNMP/SMB).
* **Storage: Physical:** SMART status honeycomb and drive temperature graphs with trigger lines.
* **Storage: Logical:** RAID group status and IOPS/latency graphs.
* **Network & Services:** Interface status honeycomb and traffic graphs.
* **Hardware Health:** CPU temperature, per-core utilization and fan status.

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
| NVMe drive in a QM2 card reported as SAS | QTS reports it this way over SNMP | Cosmetic; no fix in the template |
| Traps never reach the file; `journalctl -u snmptrapd` shows *Permission denied* | On Debian `snmptrapd` runs as `Debian-snmp`, not as root | Owner `Debian-snmp:zabbix` on the trap file and its directory (see *Requirements*, point 3) |
| `snmptrapd` is `active`, but the journal says *no access control information configured … will NOT accept any incoming notifications* | `snmptrapd` cannot read `snmptrapd.conf` (e.g. `0600 root:root`), so it does not see `authCommunity` | `root:Debian-snmp`, `0640` on `snmptrapd.conf`, restart `snmptrapd` and check the journal |
| After a reboot of the server/proxy the `snmptrapd` process is not running | `snmptrapd.service` is `static`; `snmptrapd.socket` starts it only when the first trap arrives | `sudo systemctl add-wants multi-user.target snmptrapd.service` |
| Traps stop arriving after a Zabbix package upgrade | The Zabbix package post-install script runs `chown -R zabbix:zabbix /var/log/zabbix` on every install and upgrade, so `snmptrapd` (`Debian-snmp`) can no longer write the trap file there | Keep the trap file outside `/var/log/zabbix` (e.g. `/var/log/zabbix-snmptraps/`) |
| Trap shows up only as `ZBXTRAP 127.0.0.1` / unmatched | Handler does not recognise `iso.3.6.1.6.3.18.1.3.0` when no MIBs are loaded | Use the extended regular expression from the *SNMP traps* section |
| `\"` in problem names | QTS messages containing quotes are escaped by `snmptrapd` | Cosmetic |
| `snmpwalk`/`snmpget` returns *Timeout* | Wrong community or SNMP disabled in QTS | Compare the community in QTS with `{$SNMP_COMMUNITY}` on the host |

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

**Wersja szablonu:** 3.0.0 (Release)  
**Wymagania:** Zabbix 8.0+  
**Autor:** Grzegorz Cześnik (grzegorz@net59.pl)

---

## ✅ Co nowego w wersji 3.0.0 (względem 2.0.1)

* **Pułapki SNMP ze zdarzeniami QTS** z podziałem na Error (High), Warning i pozostałe (Information). Treść komunikatu QTS trafia do nazwy problemu, a moduł QTS (np. `Security Center`) do tagu `qts_module`.
* **Bez progów wpisanych na sztywno:** nowe makra `{$NET.IF.UTIL.MAX}`, `{$FAN.SPEED.MIN}`, `{$EXT.FREE.MIN}`.
* **Mniej fałszywych i zdublowanych alarmów:** RAID w stanie `Initializing` nie daje już fałszywego Critical, *Interface is down* zamyka się sam, zdublowany trigger temperatury systemu wyłączony, usunięty stale otwarty problem *External Drive Connected*.
* **Spójne nazwy i dokumentacja:** skrócone nazwy wolumenów (`QTS (Pool 1)`), tagi `component` + `scope` wszędzie, opisy EN/PL w każdym obiekcie.
* **Format eksportu Zabbix 8.0.**

Pełna lista: [CHANGELOG.md](CHANGELOG.md).

---

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

Makra dla wolumenów obsługują kontekst, więc próg dla pojedynczego wolumenu ustawisz na hoście (np. `{$VFS.FREE.MIN.WARN:"[Volume QTS, Pool 1]"}`).

| Makro | Wartość domyślna | Opis |
|---|---|---|
| `{$CPU.UTIL.CRIT}` | `90` | Krytyczne obciążenie CPU (%), liczone jako średnia z 10 minut. |
| `{$EXT.FREE.MIN}` | `10` | Próg małej ilości wolnego miejsca na dyskach zewnętrznych USB/eSATA (%). |
| `{$FAN.SPEED.MIN}` | `200` | Minimalna prędkość wentylatora (RPM); poniżej wentylator jest traktowany jako zatrzymany. |
| `{$NET.IF.IFNAME.MATCHES}` | `^eth[0-3]$` | Wyrażenie regularne dla fizycznych interfejsów sieciowych do odkrycia. |
| `{$NET.IF.IFNAME.NOT_MATCHES}` | `(veth\|vnet\|docker\|lo\|lxc\|qvs\|dummy\|tun)` | Wyrażenie regularne wykluczające interfejsy wirtualne z odkrywania. |
| `{$NET.IF.UTIL.MAX}` | `80` | Próg wykorzystania interfejsu (%), wejście lub wyjście, jako minimum z 10 minut. |
| `{$QNAP.WEB.PORT}` | `8080` | Port TCP interfejsu WWW QTS, używany do sprawdzenia usługi. |
| `{$TEMP.CPU.CRIT}` | `85` | Krytyczna temperatura CPU (°C). |
| `{$TEMP.DISK.CRIT}` | `60` | Krytyczna temperatura dysku (°C). |
| `{$TEMP.DISK.WARN}` | `50` | Ostrzegawcza temperatura dysku (°C). |
| `{$TEMP.SYSTEM.CRIT}` | `65` | Krytyczna temperatura systemu (płyty głównej) (°C). |
| `{$VFS.FREE.MIN.CRIT}` | `10` | Krytycznie mało wolnego miejsca na wolumenie (%). |
| `{$VFS.FREE.MIN.WARN}` | `20` | Mało wolnego miejsca na wolumenie (%). |

**Community SNMP:** nie trzymaj go w szablonie. W interfejsie SNMP hosta ustaw community na `{$SNMP_COMMUNITY}`, a makro zdefiniuj na hoście jako *Secret text*. Nie używaj `public`.

---

## 🔍 Reguły Low-Level Discovery (LLD)

* **Ethernet Interface Discovery**: ruch In/Out, prędkość (`ifHighSpeed`), błędy, odrzucenia i stan operacyjny (interfejsy wirtualne odfiltrowane).
* **System Component Discovery**: temperatury jednostki głównej i jednostek rozszerzających. *Reguła LLD Override ignoruje temperaturę `-100` zgłaszaną przez karty QM2 PCIe.*
* **CPU Core Discovery**: obciążenie każdego rdzenia.
* **Disk Performance Discovery**: IOPS i opóźnienie dla każdego wolumenu logicznego.
* **Physical Drive Discovery**: temperatury, pojemność, kody i statusy SMART wszystkich dysków (HDD/SSD/NVMe).
* **External Drive Discovery (USB/eSATA)**: stan podłączenia i pojemność.
* **Fan Discovery**: prędkość (RPM) i status kontrolera wentylatora.
* **RAID Group Discovery**: status macierzy (stany QTS zamienione na kody liczbowe), pojemność i postęp odbudowy.
* **Logical Volume Discovery**: wolne miejsce, rozmiar całkowity i zajętość.

---

## 📊 Dashboard

Wbudowany, wielostronicowy dashboard (pokaz slajdów startuje automatycznie):
* **System Overview:** wskaźniki CPU, pamięci i temperatury systemu; dostępność usług (Ping/SNMP/SMB).
* **Storage: Physical:** statusy SMART na kafelkach Honeycomb i wykresy temperatur dysków z liniami progów.
* **Storage: Logical:** status grup RAID i wykresy IOPS/opóźnienia.
* **Network & Services:** statusy interfejsów na kafelkach Honeycomb i wykresy ruchu.
* **Hardware Health:** temperatura CPU, obciążenie rdzeni i status wentylatorów.

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
| Dysk NVMe na karcie QM2 raportowany jako SAS | Tak QTS raportuje go przez SNMP | Kosmetyczne; brak poprawki w szablonie |
| Pułapki nigdy nie trafiają do pliku, w `journalctl -u snmptrapd` jest *Permission denied* | W Debianie `snmptrapd` działa jako `Debian-snmp`, nie jako root | Właściciel `Debian-snmp:zabbix` pliku pułapek i jego katalogu (patrz *Wymagania*, punkt 3) |
| `snmptrapd` jest `active`, ale w dzienniku jest *no access control information configured … will NOT accept any incoming notifications* | `snmptrapd` nie może odczytać `snmptrapd.conf` (np. `0600 root:root`), więc nie widzi `authCommunity` | `root:Debian-snmp`, `0640` dla `snmptrapd.conf`, restart `snmptrapd` i kontrola dziennika |
| Po restarcie serwera/proxy proces `snmptrapd` nie działa | `snmptrapd.service` ma stan `static`; `snmptrapd.socket` uruchamia go dopiero przy pierwszej pułapce | `sudo systemctl add-wants multi-user.target snmptrapd.service` |
| Pułapki przestają dochodzić po aktualizacji pakietu Zabbix | Skrypt poinstalacyjny pakietu Zabbix przy każdej instalacji i aktualizacji wykonuje `chown -R zabbix:zabbix /var/log/zabbix`, więc `snmptrapd` (`Debian-snmp`) traci prawo zapisu do pliku pułapek | Trzymaj plik pułapek poza `/var/log/zabbix` (np. `/var/log/zabbix-snmptraps/`) |
| Pułapka pojawia się tylko jako `ZBXTRAP 127.0.0.1` / niedopasowana | Handler nie rozpoznaje `iso.3.6.1.6.3.18.1.3.0`, gdy MIB-y nie są wczytane | Użyj rozszerzonego wyrażenia regularnego z sekcji *Pułapki SNMP* |
| `\"` w nazwach problemów | `snmptrapd` poprzedza cudzysłowy w komunikatach QTS ukośnikiem | Kosmetyczne |
| `snmpwalk`/`snmpget` zwraca *Timeout* | Złe community albo wyłączone SNMP w QTS | Porównaj community w QTS z makrem `{$SNMP_COMMUNITY}` na hoście |

---

## 📝 Historia zmian

Zobacz [CHANGELOG.md](CHANGELOG.md).
