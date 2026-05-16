# Zabbix Template: SNMP QNAP TVS-473e

An optimized, native SNMP template for QNAP NAS devices (tested on TVS-473e and TS-251). Designed for production environments, leveraging Zabbix 7.4+ features including Honeycomb widgets, advanced JavaScript preprocessing, context macros, and dependency trees to prevent alert fatigue.

**Template version:** 2.0.1 (Release)  
**Requires:** Zabbix 7.4+ (due to dashboard widgets)  
**Author:** Grzegorz Cze?nik (grzegorz@net59.pl)

---

## ? What's New in Version 2.0.1 (vs 2.0.0)

### ?? Bug Fixes
* **Value map `QNAP RAID Status`:** Added missing entry `11 ↙ Failed`. Previously, when a RAID array entered the critical Failed state, Zabbix displayed a raw numeric value instead of a human-readable label.
* **Trigger `SMB Service is Down on {HOST.NAME}`:** Added missing `opdata` and `description` fields with a diagnostic instruction. This trigger was the only one in the template lacking these fields.

### ?? Improved Item Descriptions
* **`{#DRIVESLOT}: SMART Status Code`** 〞 Replaced placeholder `ok` with a proper bilingual description explaining the numeric code logic and the relationship with the SMART Status Text item.
* **`{#VOLUMENAME}: Free space`** 〞 Replaced placeholder `un` with a bilingual description documenting the JavaScript preprocessing and the purpose of the item.
* **`{#VOLUMENAME}: Total size`** 〞 Replaced placeholder `un` with a bilingual description documenting the JavaScript preprocessing and the purpose of the item.

---

## ?? What's New in Version 2.0.0 (vs RC 1.0)

Version 2.0.0 is a major overhaul of the alerting logic and polling performance. The main goal was to eliminate false positives and make the template truly production-ready by addressing the quirks of the QTS SNMP agent.

### ??? Fixes & Optimizations
* **Database Throttling:** Added `Discard unchanged with heartbeat` (from 1h to 24h) to all static inventory items. This significantly reduces DB I/O for data that rarely changes (like model names or serial numbers).
* **Polling Rate Tuning:** Item intervals were adjusted to prevent choking the QTS `snmpd` daemon under heavy load. Critical metrics (Network, CPU) are polled every 1m, hardware health (Disks, Fans, RAID) every 5m, and capacity metrics every 15m.
* **Negative Error Code Support:** Changed LLD data types for Fans and SMART codes from `Unsigned` to `Numeric (float)`. QNAP uses `-1` to report hardware failures, which previously caused items to become "Not Supported".

### ?? Advanced Logic (JavaScript Preprocessing)
* **Multi-State RAID Parser:** RAID statuses are now handled by a custom JS script that maps 11 native QTS textual states into strict numeric values. This allows Zabbix to distinguish between a failure (e.g., Degraded) and standard maintenance (e.g., Rebuilding).
* **USB Drive Parser:** QNAP reports USB drive capacity as a string (e.g., "1.50 TB"). A JS script now parses these strings into raw bytes on the fly, allowing capacity triggers to work correctly.

### ??? Alert Fatigue Reduction
* **Service Dependency Tree:** Network/Agent failures now suppress child alerts. If Ping or SNMP goes down, alerts for SMB, QTS Web, or `nodata` triggers are automatically hidden.
* **Network Hysteresis:** The `Interface is down` trigger now only reacts to ports that were previously `Up` (`last(#2)=1`). Empty switch ports no longer generate false alarms.
* **Performance Spike Filtering:** Network bandwidth (`>80%`) and CPU utilization (`>90%`) triggers now use `min(10m)` and `avg(10m)` functions to ignore short spikes and only alert on sustained loads.

---

## ?? Macros

The template is fully configurable. Volume macros support context, allowing you to set custom thresholds for specific logical drives directly on the host (e.g., `{$VFS.FREE.MIN.WARN:"[Volume QTS, Pool 1]"}`).

| Macro | Default | Description |
|---|---|---|
| `{$CPU.UTIL.CRIT}` | `90` | Critical CPU utilization threshold (%). Used by a trigger analyzing average load over 10 minutes. |
| `{$NET.IF.IFNAME.MATCHES}` | `^eth[0-9]+$` | RegEx for physical network ports to be monitored. |
| `{$NET.IF.IFNAME.NOT_MATCHES}`| `(veth\|vnet\|docker\|lo\|lxc\|qvs\|dummy\|tun)` | RegEx to exclude virtual interfaces (Docker/VMs) from discovery. |
| `{$QNAP.WEB.PORT}` | `8080` | QTS administration interface port. Used for the TCP service availability test. |
| `{$TEMP.CPU.CRIT}` | `85` | Critical CPU temperature threshold. Above this, thermal throttling may occur. |
| `{$TEMP.DISK.CRIT}` | `60` | Critical threshold for drive temperature. Exceeding this increases the risk of drive failure. |
| `{$TEMP.DISK.WARN}` | `50` | Warning threshold for drive temperature. Suggests poor air circulation. |
| `{$TEMP.SYSTEM.CRIT}` | `65` | Critical system (motherboard/enclosure) temperature threshold. |
| `{$VFS.FREE.MIN.CRIT}` | `10` | Critically low free space on a volume (%). Threshold for high-priority alarms. |
| `{$VFS.FREE.MIN.WARN}` | `20` | Warning for low free space on a volume (%). |

---

## ?? Low-Level Discovery (LLD) Rules

The template automatically discovers and monitors:
* **Ethernet Interface Discovery**: In/Out traffic, speeds, errors, discards, and operational states (filters out Docker/veth interfaces).
* **System Component Discovery**: Temperatures of enclosures and expansion units. *Includes an LLD Override to ignore the `-100` temperature error reported by QM2 PCIe cards.*
* **CPU Core Discovery**: Utilization per individual CPU core.
* **Disk Performance Discovery**: IOPS and Latency for logical volumes.
* **Physical Drive Discovery**: Temperatures, capacities, SMART codes, and statuses for all drives (HDD/SSD/NVMe).
* **External Drive Discovery (USB/eSATA)**: Connection status and capacity of external drives.
* **Fan Discovery**: RPM speeds and cooling controller statuses.
* **RAID Group Discovery**: Array status (11 QTS states), capacity, and rebuilding progress.
* **Logical Volume Discovery**: Mathematical calculation of space utilization.

---

## ?? Dashboard (Zabbix 7.4)

The template includes a built-in, multi-page NOC-style Dashboard:
* **System Overview:** Gauges for CPU, Memory, and System Temp with a clean layout. Service availability (Ping/SNMP/SMB) visualized with Sparklines.
* **Storage Physical:** SMART statuses via Honeycomb widgets and Disk Temperature graphs featuring *Simple Triggers* reference lines.
* **Storage Logical:** Current RAID group statuses (Green=Ready, Orange=Rebuilding, Red=Degraded) and detailed IOPS/Latency tracking.
* **Network & Services:** Clean Honeycomb interface statuses (using `regsub` to strip unnecessary hostnames) and aggregated traffic graphs.
* **Hardware Health:** CPU Temp, core utilization (Staircase graphs), and Fan status with support for controller failure codes.

---

## ?? Installation & Best Practices

1. Download the `SNMP QNAP TVS-473e.yaml` file.
2. Log in to Zabbix (v7.4+ is required for the dashboard widgets).
3. Go to **Data collection** -> **Templates** -> Click **Import**.
4. Assign the template to your QNAP host (ensure SNMPv2c is enabled in the QTS control panel).
5. **CRITICAL:** In the Host settings under the SNMP interface, **uncheck the `Use bulk requests` option**. QNAP's SNMP daemon is known to drop bulk requests under heavy I/O, which causes false `[no data]` triggers.
6. Ensure your Zabbix Server/Proxy `Timeout` is set to at least `10s` (or `15s`) in the configuration file.

<br>
<br>

***
<br>
<br>

# Szablon Zabbix: SNMP QNAP TVS-473e

Zoptymalizowany, natywny szablon SNMP dla serwer車w NAS firmy QNAP (testowany na modelach TVS-473e oraz TS-251). Szablon zosta? zaprojektowany z my?l? o ?rodowiskach produkcyjnych, wykorzystuj?c funkcje Zabbix 7.4+ (m.in. widgety Honeycomb, preprocesing JavaScript, makra z kontekstem oraz drzewa zale?no?ci), aby zapobiega? fa?szywym alarmom.

**Wersja szablonu:** 2.0.1 (Release)  
**Wymagania:** Zabbix 7.4+ (ze wzgl?du na format widget車w Dashboardu)  
**Autor:** Grzegorz Cze?nik (grzegorz@net59.pl)

---

## ? Co nowego w wersji 2.0.1 (wzgl?dem 2.0.0)

### ?? Poprawki b??d車w
* **Value mapa `QNAP RAID Status`:** Dodano brakuj?cy wpis `11 ↙ Failed`. Wcze?niej, gdy macierz RAID wchodzi?a w stan krytyczny "Failed", Zabbix wy?wietla? surow? warto?? liczbow? zamiast czytelnego opisu.
* **Trigger `SMB Service is Down on {HOST.NAME}`:** Dodano brakuj?ce pola `opdata` oraz `description` z instrukcj? diagnostyczn?. Trigger by? jedynym w szablonie bez tych p車l.

### ?? Poprawiono opisy item車w
* **`{#DRIVESLOT}: SMART Status Code`** 〞 Zast?piono placeholder `ok` w?a?ciwym opisem dwuj?zycznym wyja?niaj?cym logik? kod車w numerycznych oraz relacj? z itemem SMART Status Text.
* **`{#VOLUMENAME}: Free space`** 〞 Zast?piono placeholder `un` opisem dwuj?zycznym dokumentuj?cym preprocessing JavaScript i przeznaczenie itemu.
* **`{#VOLUMENAME}: Total size`** 〞 Zast?piono placeholder `un` opisem dwuj?zycznym dokumentuj?cym preprocessing JavaScript i przeznaczenie itemu.

---

## ?? Co nowego w wersji 2.0.0 (wzgl?dem RC 1.0)

Wersja 2.0.0 to gruntowna przebudowa logiki alarmowania oraz optymalizacja zapyta里 SNMP. G?車wnym celem by?o wyeliminowanie fa?szywych alarm車w i dostosowanie szablonu do reali車w pracy agenta SNMP w systemach QTS.

### ??? Poprawki i Optymalizacja
* **Odci??enie bazy danych Zabbix:** Dodano regu?y `Discard unchanged with heartbeat` (od 1h do 24h) dla wszystkich statycznych parametr車w inwentaryzacyjnych, co znacz?co redukuje zapisy do bazy danych.
* **Dostosowanie interwa?車w (Polling Rate):** Zmieniono czasy odpytywania, aby zapobiec "d?awieniu si?" demona `snmpd` w QTS pod du?ym obci??eniem. Parametry krytyczne (Sie?, CPU) odpytywane s? co 1m, sprz?t (Dyski, Wentylatory, RAID) co 5m, a dane pojemno?ciowe co 15m.
* **Obs?uga ujemnych kod車w b??d車w:** Zmieniono typy danych w LLD dla Wentylator車w i SMART z `Unsigned` na `Numeric (float)`. QNAP u?ywa warto?ci `-1` do raportowania awarii, co wcze?niej skutkowa?o b??dem "Not Supported" w Zabbixie.

### ?? Zaawansowana Logika (JavaScript Preprocessing)
* **Wielostanowy Parser RAID:** Statusy RAID s? teraz przetwarzane przez autorski skrypt JS, kt車ry mapuje 11 natywnych stan車w tekstowych z MIB na konkretne warto?ci liczbowe. Dzi?ki temu system bezb??dnie odr車?nia awari? (np. Degraded) od prac konserwacyjnych (np. Rebuilding).
* **Parser Dysk車w USB:** QNAP raportuje zaj?to?? dysk車w USB jako tekst (np. "1.50 TB"). Skrypt JS w locie przelicza te jednostki na bajty, umo?liwiaj?c prawid?owe dzia?anie trigger車w matematycznych.

### ??? Redukcja fa?szywych alarm車w
* **Drzewo Zale?no?ci Us?ug:** Awarie sieci lub agenta SNMP natychmiast ukrywaj? podrz?dne alerty. Brak odpowiedzi na Ping lub b??d SNMP wycisza powiadomienia o niedost?pno?ci SMB, WWW czy braku danych z czujnik車w (`nodata`).
* **Histereza Sieciowa:** Trigger `Interface is down` reaguje wy??cznie na porty, kt車re wcze?niej by?y pod??czone (`last(#2)=1`). Puste gniazda na switchu nie generuj? ju? fa?szywych alarm車w o utracie po??czenia.
* **Filtrowanie skok車w wydajno?ci:** Utylizacja pasma sieciowego (`>80%`) oraz procesora (`>90%`) wykorzystuje okna czasowe `min(10m)` i `avg(10m)`. System ignoruje kr車tkie zatory, alarmuj?c tylko o trwa?ym przeci??eniu.

---

## ?? Makra (Macros)

Szablon jest w pe?ni konfigurowalny. Makra dla wolumen車w obs?uguj? **makra z kontekstem**, co pozwala na ustawienie indywidualnych prog車w dla konkretnych dysk車w logicznych na poziomie hosta (np. `{$VFS.FREE.MIN.WARN:"[Volume QTS, Pool 1]"}`).

| Makro | Warto?? domy?lna | Opis |
|---|---|---|
| `{$CPU.UTIL.CRIT}` | `90` | Pr車g krytycznego obci??enia procesora (%). Wykorzystywany przez trigger analizuj?cy ?rednie obci??enie z 10 minut. |
| `{$NET.IF.IFNAME.MATCHES}` | `^eth[0-9]+$` | Wyra?enie regularne dla fizycznych port車w sieciowych, kt車re maj? by? monitorowane. |
| `{$NET.IF.IFNAME.NOT_MATCHES}`| `(veth\|vnet\|docker\|lo\|lxc\|qvs\|dummy\|tun)` | Wyra?enie regularne odrzucaj?ce wirtualne interfejsy (Docker/wirtualizacja) z mechanizmu discovery. |
| `{$QNAP.WEB.PORT}` | `8080` | Port interfejsu administracyjnego QTS. Wykorzystywany do testu us?ugi TCP. |
| `{$TEMP.CPU.CRIT}` | `85` | Pr車g krytyczny temperatury procesora. Powy?ej tej warto?ci mo?e doj?? do d?awienia termicznego (throttling). |
| `{$TEMP.DISK.CRIT}` | `60` | Pr車g krytyczny temperatury dysk車w. Przekroczenie drastycznie zwi?ksza ryzyko awarii i utraty danych. |
| `{$TEMP.DISK.WARN}` | `50` | Pr車g ostrzegawczy temperatury dysk車w. Warto?ci powy?ej sugeruj? s?ab? cyrkulacj? powietrza. |
| `{$TEMP.SYSTEM.CRIT}` | `65` | Pr車g krytyczny temperatury p?yty g?車wnej (System) lub jednostek rozszerzaj?cych. |
| `{$VFS.FREE.MIN.CRIT}` | `10` | Krytycznie ma?o miejsca na wolumenie (%). Pr車g dla alarm車w o wysokim priorytecie. |
| `{$VFS.FREE.MIN.WARN}` | `20` | Ostrze?enie o ma?ej ilo?ci wolnego miejsca na wolumenie (%). |

---

## ?? Regu?y Low-Level Discovery (LLD)

Szablon automatycznie wykrywa i monitoruje:
* **Ethernet Interface Discovery**: Ruch (In/Out), pr?dko?ci, b??dy CRC, stany operacyjne (z filtrowaniem port車w wirtualnych).
* **System Component Discovery**: Temperatury obud車w i jednostek rozszerzaj?cych. *Dodano regu?? LLD Override, kt車ra ignoruje b??d czujnika temperatury (-100) dla kart QM2 PCIe.*
* **CPU Core Discovery**: Utylizacja zasob車w z podzia?em na poszczeg車lne rdzenie procesora.
* **Disk Performance Discovery**: IOPS oraz Latency (Op車?nienia) dla poszczeg車lnych wolumen車w (LUN).
* **Physical Drive Discovery**: Temperatury, pojemno?ci oraz kody i statusy S.M.A.R.T. wszystkich dysk車w.
* **External Drive Discovery (USB/eSATA)**: Monitorowanie statusu pod??czenia oraz zaj?to?ci dysk車w zewn?trznych.
* **Fan Discovery**: Pr?dko?? obrotowa (RPM) oraz statusy kontroler車w wentylator車w.
* **RAID Group Discovery**: Monitorowanie statusu macierzy (11 stan車w z QTS), pojemno?ci i procentowego post?pu odbudowy.
* **Logical Volume Discovery**: Obliczanie procentowego zu?ycia zasob車w dyskowych.

---

## ?? Dashboard (Zabbix 7.4 Unified)

Szablon dostarcza wbudowany, wielozak?adkowy Dashboard zaprojektowany w standardach NOC (Network Operations Center):
* **System Overview:** G?車wne wska?niki (Gauge) dla CPU, Pami?ci i Temperatury. Sparklines dla dost?pno?ci us?ug (Ping/SNMP/SMB).
* **Storage Physical:** Statusy SMART wy?wietlane na kafelkach Honeycomb oraz wykresy temperatur dysk車w z naniesionymi progami alarmowymi (Simple Triggers).
* **Storage Logical:** Aktualny status grup RAID (Zielony=Ready, Pomara里czowy=Rebuilding, Czerwony=Degraded) oraz wykresy wydajno?ci IOPS i Latency.
* **Network & Services:** Statusy port車w na kafelkach Honeycomb (zastosowano `regsub` do usuni?cia zb?dnych nazw host車w) oraz czytelne wykresy ruchu.
* **Hardware Health:** Temperatura procesora, obci??enie rdzeni (wykresy typu Staircase / schodkowe) oraz weryfikacja statusu wentylator車w z obs?ug? kod車w b??d車w.

---

## ?? Instalacja i Dobre Praktyki

1. Pobierz plik `SNMP QNAP TVS-473e.yaml`.
2. Zaloguj si? do Zabbix (wymagana wersja 7.4+ dla poprawnego wy?wietlania nowych typ車w widget車w).
3. Przejd? do **Data collection** -> **Templates** -> Kliknij **Import**.
4. Powi?? szablon z wybranym hostem QNAP (pami?taj o w??czeniu us?ugi SNMPv2c w panelu QTS).
5. **KRYTYCZNE:** W ustawieniach Hosta, w sekcji interfejsu SNMP, opcja **Use bulk requests** musi by? **odznaczona**. Agent SNMP w QNAP cz?sto odrzuca masowe zapytania pod du?ym obci??eniem I/O, co generuje fa?szywe powiadomienia o braku danych (`nodata`).
6. Upewnij si?, ?e parametr `Timeout` w pliku konfiguracyjnym serwera Zabbix lub Proxy wynosi minimum `10s` do `15s`.