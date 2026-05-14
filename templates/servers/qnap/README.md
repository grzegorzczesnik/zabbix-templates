# Zabbix Template: SNMP QNAP TVS-473e

An optimized, native SNMP template for QNAP NAS devices (tested on TVS-473e and TS-251). Designed for production environments, leveraging Zabbix 7.4+ features including Honeycomb widgets, advanced JavaScript preprocessing, context macros, and dependency trees to prevent alert fatigue.

**Template version:** 2.0.0 (Release)  
**Requires:** Zabbix 7.4+ (due to dashboard widgets)  
**Author:** Grzegorz Cześnik (grzegorz@net59.pl)

---

## 🚀 What's New in Version 2.0.0 (vs RC 1.0)

Version 2.0.0 is a major overhaul of the alerting logic and polling performance. The main goal was to eliminate false positives and make the template truly production-ready by addressing the quirks of the QTS SNMP agent.

### 🛠 Fixes & Optimizations
* **Database Throttling:** Added `Discard unchanged with heartbeat` (from 1h to 24h) to all static inventory items. This significantly reduces DB I/O for data that rarely changes (like model names or serial numbers).
* **Polling Rate Tuning:** Item intervals were adjusted to prevent choking the QTS `snmpd` daemon under heavy load. Critical metrics (Network, CPU) are polled every 1m, hardware health (Disks, Fans, RAID) every 5m, and capacity metrics every 15m.
* **Negative Error Code Support:** Changed LLD data types for Fans and SMART codes from `Unsigned` to `Numeric (float)`. QNAP uses `-1` to report hardware failures, which previously caused items to become "Not Supported".

### 🧠 Advanced Logic (JavaScript Preprocessing)
* **Multi-State RAID Parser:** RAID statuses are now handled by a custom JS script that maps 11 native QTS textual states into strict numeric values. This allows Zabbix to distinguish between a failure (e.g., Degraded) and standard maintenance (e.g., Rebuilding).
* **USB Drive Parser:** QNAP reports USB drive capacity as a string (e.g., "1.50 TB"). A JS script now parses these strings into raw bytes on the fly, allowing capacity triggers to work correctly.

### 🛡 Alert Fatigue Reduction
* **Service Dependency Tree:** Network/Agent failures now suppress child alerts. If Ping or SNMP goes down, alerts for SMB, QTS Web, or `nodata` triggers are automatically hidden.
* **Network Hysteresis:** The `Interface is down` trigger now only reacts to ports that were previously `Up` (`last(#2)=1`). Empty switch ports no longer generate false alarms.
* **Performance Spike Filtering:** Network bandwidth (`>80%`) and CPU utilization (`>90%`) triggers now use `min(10m)` and `avg(10m)` functions to ignore short spikes and only alert on sustained loads.

---

## ⚙️ Macros

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

## 🔍 Low-Level Discovery (LLD) Rules

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

## 📊 Dashboard (Zabbix 7.4)

The template includes a built-in, multi-page NOC-style Dashboard:
* **System Overview:** Gauges for CPU, Memory, and System Temp with a clean layout. Service availability (Ping/SNMP/SMB) visualized with Sparklines.
* **Storage Physical:** SMART statuses via Honeycomb widgets and Disk Temperature graphs featuring *Simple Triggers* reference lines.
* **Storage Logical:** Current RAID group statuses (Green=Ready, Orange=Rebuilding, Red=Degraded) and detailed IOPS/Latency tracking.
* **Network & Services:** Clean Honeycomb interface statuses (using `regsub` to strip unnecessary hostnames) and aggregated traffic graphs.
* **Hardware Health:** CPU Temp, core utilization (Staircase graphs), and Fan status with support for controller failure codes.

---

## ⚙️ Installation & Best Practices

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

Zoptymalizowany, natywny szablon SNMP dla serwerów NAS firmy QNAP (testowany na modelach TVS-473e oraz TS-251). Szablon został zaprojektowany z myślą o środowiskach produkcyjnych, wykorzystując funkcje Zabbix 7.4+ (m.in. widgety Honeycomb, preprocesing JavaScript, makra z kontekstem oraz drzewa zależności), aby zapobiegać fałszywym alarmom.

**Wersja szablonu:** 2.0.0 (Release)  
**Wymagania:** Zabbix 7.4+ (ze względu na format widgetów Dashboardu)  
**Autor:** Grzegorz Cześnik (grzegorz@net59.pl)

---

## 🚀 Co nowego w wersji 2.0.0 (względem RC 1.0)

Wersja 2.0.0 to gruntowna przebudowa logiki alarmowania oraz optymalizacja zapytań SNMP. Głównym celem było wyeliminowanie fałszywych alarmów i dostosowanie szablonu do realiów pracy agenta SNMP w systemach QTS.

### 🛠 Poprawki i Optymalizacja
* **Odciążenie bazy danych Zabbix:** Dodano reguły `Discard unchanged with heartbeat` (od 1h do 24h) dla wszystkich statycznych parametrów inwentaryzacyjnych, co znacząco redukuje zapisy do bazy danych.
* **Dostosowanie interwałów (Polling Rate):** Zmieniono czasy odpytywania, aby zapobiec "dławieniu się" demona `snmpd` w QTS pod dużym obciążeniem. Parametry krytyczne (Sieć, CPU) odpytywane są co 1m, sprzęt (Dyski, Wentylatory, RAID) co 5m, a dane pojemnościowe co 15m.
* **Obsługa ujemnych kodów błędów:** Zmieniono typy danych w LLD dla Wentylatorów i SMART z `Unsigned` na `Numeric (float)`. QNAP używa wartości `-1` do raportowania awarii, co wcześniej skutkowało błędem "Not Supported" w Zabbixie.

### 🧠 Zaawansowana Logika (JavaScript Preprocessing)
* **Wielostanowy Parser RAID:** Statusy RAID są teraz przetwarzane przez autorski skrypt JS, który mapuje 11 natywnych stanów tekstowych z MIB na konkretne wartości liczbowe. Dzięki temu system bezbłędnie odróżnia awarię (np. Degraded) od prac konserwacyjnych (np. Rebuilding).
* **Parser Dysków USB:** QNAP raportuje zajętość dysków USB jako tekst (np. "1.50 TB"). Skrypt JS w locie przelicza te jednostki na bajty, umożliwiając prawidłowe działanie triggerów matematycznych.

### 🛡 Redukcja fałszywych alarmów
* **Drzewo Zależności Usług:** Awarie sieci lub agenta SNMP natychmiast ukrywają podrzędne alerty. Brak odpowiedzi na Ping lub błąd SNMP wycisza powiadomienia o niedostępności SMB, WWW czy braku danych z czujników (`nodata`).
* **Histereza Sieciowa:** Trigger `Interface is down` reaguje wyłącznie na porty, które wcześniej były podłączone (`last(#2)=1`). Puste gniazda na switchu nie generują już fałszywych alarmów o utracie połączenia.
* **Filtrowanie skoków wydajności:** Utylizacja pasma sieciowego (`>80%`) oraz procesora (`>90%`) wykorzystuje okna czasowe `min(10m)` i `avg(10m)`. System ignoruje krótkie zatory, alarmując tylko o trwałym przeciążeniu.

---

## ⚙️ Makra (Macros)

Szablon jest w pełni konfigurowalny. Makra dla wolumenów obsługują **makra z kontekstem**, co pozwala na ustawienie indywidualnych progów dla konkretnych dysków logicznych na poziomie hosta (np. `{$VFS.FREE.MIN.WARN:"[Volume QTS, Pool 1]"}`).

| Makro | Wartość domyślna | Opis |
|---|---|---|
| `{$CPU.UTIL.CRIT}` | `90` | Próg krytycznego obciążenia procesora (%). Wykorzystywany przez trigger analizujący średnie obciążenie z 10 minut. |
| `{$NET.IF.IFNAME.MATCHES}` | `^eth[0-9]+$` | Wyrażenie regularne dla fizycznych portów sieciowych, które mają być monitorowane. |
| `{$NET.IF.IFNAME.NOT_MATCHES}`| `(veth\|vnet\|docker\|lo\|lxc\|qvs\|dummy\|tun)` | Wyrażenie regularne odrzucające wirtualne interfejsy (Docker/wirtualizacja) z mechanizmu discovery. |
| `{$QNAP.WEB.PORT}` | `8080` | Port interfejsu administracyjnego QTS. Wykorzystywany do testu usługi TCP. |
| `{$TEMP.CPU.CRIT}` | `85` | Próg krytyczny temperatury procesora. Powyżej tej wartości może dojść do dławienia termicznego (throttling). |
| `{$TEMP.DISK.CRIT}` | `60` | Próg krytyczny temperatury dysków. Przekroczenie drastycznie zwiększa ryzyko awarii i utraty danych. |
| `{$TEMP.DISK.WARN}` | `50` | Próg ostrzegawczy temperatury dysków. Wartości powyżej sugerują słabą cyrkulację powietrza. |
| `{$TEMP.SYSTEM.CRIT}` | `65` | Próg krytyczny temperatury płyty głównej (System) lub jednostek rozszerzających. |
| `{$VFS.FREE.MIN.CRIT}` | `10` | Krytycznie mało miejsca na wolumenie (%). Próg dla alarmów o wysokim priorytecie. |
| `{$VFS.FREE.MIN.WARN}` | `20` | Ostrzeżenie o małej ilości wolnego miejsca na wolumenie (%). |

---

## 🔍 Reguły Low-Level Discovery (LLD)

Szablon automatycznie wykrywa i monitoruje:
* **Ethernet Interface Discovery**: Ruch (In/Out), prędkości, błędy CRC, stany operacyjne (z filtrowaniem portów wirtualnych).
* **System Component Discovery**: Temperatury obudów i jednostek rozszerzających. *Dodano regułę LLD Override, która ignoruje błąd czujnika temperatury (-100) dla kart QM2 PCIe.*
* **CPU Core Discovery**: Utylizacja zasobów z podziałem na poszczególne rdzenie procesora.
* **Disk Performance Discovery**: IOPS oraz Latency (Opóźnienia) dla poszczególnych wolumenów (LUN).
* **Physical Drive Discovery**: Temperatury, pojemności oraz kody i statusy S.M.A.R.T. wszystkich dysków.
* **External Drive Discovery (USB/eSATA)**: Monitorowanie statusu podłączenia oraz zajętości dysków zewnętrznych.
* **Fan Discovery**: Prędkość obrotowa (RPM) oraz statusy kontrolerów wentylatorów.
* **RAID Group Discovery**: Monitorowanie statusu macierzy (11 stanów z QTS), pojemności i procentowego postępu odbudowy.
* **Logical Volume Discovery**: Obliczanie procentowego zużycia zasobów dyskowych.

---

## 📊 Dashboard (Zabbix 7.4 Unified)

Szablon dostarcza wbudowany, wielozakładkowy Dashboard zaprojektowany w standardach NOC (Network Operations Center):
* **System Overview:** Główne wskaźniki (Gauge) dla CPU, Pamięci i Temperatury. Sparklines dla dostępności usług (Ping/SNMP/SMB).
* **Storage Physical:** Statusy SMART wyświetlane na kafelkach Honeycomb oraz wykresy temperatur dysków z naniesionymi progami alarmowymi (Simple Triggers).
* **Storage Logical:** Aktualny status grup RAID (Zielony=Ready, Pomarańczowy=Rebuilding, Czerwony=Degraded) oraz wykresy wydajności IOPS i Latency.
* **Network & Services:** Statusy portów na kafelkach Honeycomb (zastosowano `regsub` do usunięcia zbędnych nazw hostów) oraz czytelne wykresy ruchu.
* **Hardware Health:** Temperatura procesora, obciążenie rdzeni (wykresy typu Staircase / schodkowe) oraz weryfikacja statusu wentylatorów z obsługą kodów błędów.

---

## ⚙️ Instalacja i Dobre Praktyki

1. Pobierz plik `SNMP QNAP TVS-473e.yaml`.
2. Zaloguj się do Zabbix (wymagana wersja 7.4+ dla poprawnego wyświetlania nowych typów widgetów).
3. Przejdź do **Data collection** -> **Templates** -> Kliknij **Import**.
4. Powiąż szablon z wybranym hostem QNAP (pamiętaj o włączeniu usługi SNMPv2c w panelu QTS).
5. **KRYTYCZNE:** W ustawieniach Hosta, w sekcji interfejsu SNMP, opcja **Use bulk requests** musi być **odznaczona**. Agent SNMP w QNAP często odrzuca masowe zapytania pod dużym obciążeniem I/O, co generuje fałszywe powiadomienia o braku danych (`nodata`).
6. Upewnij się, że parametr `Timeout` w pliku konfiguracyjnym serwera Zabbix lub Proxy wynosi minimum `10s` do `15s`.