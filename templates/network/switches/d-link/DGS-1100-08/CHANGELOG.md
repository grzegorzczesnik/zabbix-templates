# Changelog – SNMP D-Link DGS-1100-08

---

## 🇬🇧 English Version

### v2 – 2026-10-24

**Zabbix Version:** 7.4

Quality and correctness release: fixes triggers that could not fire or flapped, replaces the noisy CPU-stress heuristic with standard ICMP metrics, makes every port threshold tunable per port, and adds host inventory, consistent tagging, bilingual descriptions and a *Front panel* dashboard page.

#### 🐞 Fixed

- **Link flapping** trigger could never fire (`count(…,1m)` with 1-minute polling) – now `changecount(…,15m)` with the `{$IF.FLAP.MAX}` macro.
- **Utilization** items went *Not supported* on ports without link (division by zero on `ifSpeed = 0`) – formula guarded.
- **SNMP authentication failure** trigger opened and closed every polling cycle – now based on the hourly sum with the `{$SNMP.AUTH.FAIL.MAX}` macro.
- Units displayed literally (`sps (segments per second)`, `dps (datagrams per second)`) – corrected to `segments/s`, `datagrams/s`, `pps`.

#### 🗑 Removed

- `ICMP Drop Ratio (CPU Stress Indicator)` and its trigger – the difference of two counters read at different times produced noise; replaced by ICMP packet loss and response time.
- Dashboard column *CPU Stress* – replaced by *Ping Loss*.

#### ✨ Added

- **Items:** ICMP ping, ICMP packet loss, SNMP agent availability (internal item `zabbix[host,snmp,available]`), system contact.
- **Triggers:** unavailable by ICMP ping, ICMP packet loss, ICMP response time, no SNMP data collection, device restarted, inbound bandwidth utilization.
- **LLD:** filter for physical Ethernet ports (`ifType = 6`), lost resources disabled immediately and deleted after 30 days.
- **Macros:** 9 new ones (`{$ICMP_LOSS_WARN}`, `{$ICMP_RESPONSE_TIME_WARN}`, `{$SNMP.TIMEOUT}`, `{$SNMP.AUTH.FAIL.MAX}`, `{$IFCONTROL}`, `{$IF.ERRORS.WARN}`, `{$IF.DISCARDS.MAX}`, `{$IF.UNKNOWN.MAX}`, `{$IF.FLAP.MAX}`); all port thresholds are context macros, so a single port can be tuned or silenced on the host.
- **Host inventory:** Name, Location, Contact and Hardware populated from SNMP.
- **Value maps:** `Zabbix host availability`; `Interface Status` extended to all 7 `ifOperStatus` states.
- **Dashboard:** pages named *Overview* and *Front panel*; *Front panel* shows link status, speed and inbound/outbound load port by port; separate inbound and outbound utilization honeycombs.
- **Documentation:** template description, template tags (`service`, `vendor`), EN/PL descriptions on all items, triggers and macros.

#### 🔧 Changed

- Item names unified to `Category: Name` (e.g. `ICMP: Ping`, `System: Uptime`).
- Tag schema unified: `component` + `scope` everywhere, plus `interface: <port>` on port items and triggers (replaces `target` and `class`).
- Text items changed to Character.
- *Interface is down*: High → Average, can be disabled per port with `{$IFCONTROL:"portN"}`.
- Discards, errors and unknown-protocol triggers: hard-coded thresholds → context macros.
- *VLAN Mismatch or Unknown Protocol detected* renamed to the neutral *Unknown protocol frames received* (Information).

---

### v1 – 2026-01-06

#### 🚀 Major Update: "Enterprise Light" Dashboard & Zabbix 7.4 Standards

**Date:** 2026-01-06
**Zabbix Version:** 7.4+

This release introduces a complete overhaul of the visual layer (Dashboard) and standardizes the configuration for Zabbix 7.x. The template has evolved from basic data collection to a professional, NOC-grade diagnostic tool.

#### ✨ Key Changes

**1. New "Enterprise Light" Dashboard**

Replaced standard graphs with modern Honeycomb widgets utilizing a "Material Design" pastel color palette.

- **High Readability:** Switched to pastel backgrounds (e.g., #E8F5E9) with dark text to ensure contrast and readability of values (0 vs 0%).
- **Layer Separation:** Distinct widgets for different diagnostic layers:
  - **Port Status:** Hierarchical layout highlighting availability.
  - **Physical Errors (Cabling):** Dedicated widget showing only CRC/Physical errors (identifying bad cabling).
  - **Packet Drops (Discards):** Separate widget for network congestion/buffer overflows.
  - **Bandwidth Usage:** Gradient color interpolation (Green -> Yellow -> Red).
  - **System Health:** New "Top Hosts" table aggregating key metrics (UDP Noise, Auth Fails, CPU Stress, Ping Latency).

**2. User Macros Implementation**

Hardcoded trigger values have been replaced with flexible User Macros:

- `{$IF.UTIL.MAX}` - Bandwidth utilization threshold (default: 85%).
- `{$NET.UDP.NOISE.MAX}` - UDP network noise threshold.
- `{$IF.BCAST.MAX.WARN}` - Broadcast storm threshold.
- `{$IF.SPEED.MIN}` - Expected port speed.

**3. New Metrics & Logic**

- **ICMP Response Time:** Added a Simple Check item for latency monitoring (Ping Latency), providing early warning before CPU drops occur.
- **Optimization:** Applied Discard unchanged with heartbeat (1d) preprocessing to inventory and status items to significantly reduce database growth.

**4. Standardization (Zabbix 7.x)**

- **Tagging:** Full implementation of modern tagging standards for better filtering:
  - `target: interface` vs `target: device`
  - `scope: health` vs `scope: performance`

---

## 🇵🇱 Polska Wersja

### v2 – 24.10.2026

**Wersja Zabbix:** 7.4

Wydanie porządkujące jakość i poprawność: naprawia triggery, które nie mogły zadziałać albo „migały”, zastępuje zaszumioną heurystykę obciążenia CPU standardowymi metrykami ICMP, pozwala dostroić każdy próg portu osobno oraz dodaje inwentarz hosta, spójne tagi, opisy w dwóch językach i stronę dashboardu *Front panel*.

#### 🐞 Naprawione

- Trigger **flappingu łącza** nie mógł zadziałać (`count(…,1m)` przy odczycie co minutę) – teraz `changecount(…,15m)` z makrem `{$IF.FLAP.MAX}`.
- Itemy **wykorzystania pasma** przechodziły w *Not supported* na portach bez linku (dzielenie przez zero przy `ifSpeed = 0`) – formuła zabezpieczona.
- Trigger **błędów uwierzytelnienia SNMP** otwierał się i zamykał co cykl odczytu – teraz oparty na sumie godzinowej z makrem `{$SNMP.AUTH.FAIL.MAX}`.
- Jednostki wyświetlane dosłownie (`sps (segments per second)`, `dps (datagrams per second)`) – poprawione na `segments/s`, `datagrams/s`, `pps`.

#### 🗑 Usunięte

- `ICMP Drop Ratio (CPU Stress Indicator)` wraz z triggerem – różnica dwóch liczników odczytanych w różnych chwilach dawała szum; zastąpione utratą pakietów i czasem odpowiedzi ICMP.
- Kolumna dashboardu *CPU Stress* – zastąpiona przez *Ping Loss*.

#### ✨ Dodane

- **Itemy:** ICMP ping, utrata pakietów ICMP, dostępność agenta SNMP (item wewnętrzny `zabbix[host,snmp,available]`), kontakt systemowy.
- **Triggery:** niedostępność ICMP, utrata pakietów ICMP, czas odpowiedzi ICMP, brak danych SNMP, restart urządzenia, wykorzystanie pasma wejściowego.
- **LLD:** filtr fizycznych portów Ethernet (`ifType = 6`), utracone zasoby wyłączane od razu i usuwane po 30 dniach.
- **Makra:** 9 nowych (`{$ICMP_LOSS_WARN}`, `{$ICMP_RESPONSE_TIME_WARN}`, `{$SNMP.TIMEOUT}`, `{$SNMP.AUTH.FAIL.MAX}`, `{$IFCONTROL}`, `{$IF.ERRORS.WARN}`, `{$IF.DISCARDS.MAX}`, `{$IF.UNKNOWN.MAX}`, `{$IF.FLAP.MAX}`); wszystkie progi portów to makra kontekstowe, więc pojedynczy port można dostroić lub wyciszyć na hoście.
- **Inwentarz hosta:** Name, Location, Contact i Hardware wypełniane z SNMP.
- **Value mapy:** `Zabbix host availability`; `Interface Status` rozszerzona do wszystkich 7 stanów `ifOperStatus`.
- **Dashboard:** strony nazwane *Overview* i *Front panel*; *Front panel* pokazuje port po porcie stan łącza, prędkość i obciążenie wejścia/wyjścia; osobne honeycomby wykorzystania pasma wejściowego i wyjściowego.
- **Dokumentacja:** opis szablonu, tagi szablonu (`service`, `vendor`), opisy EN/PL przy wszystkich itemach, triggerach i makrach.

#### 🔧 Zmienione

- Nazwy itemów ujednolicone do `Kategoria: Nazwa` (np. `ICMP: Ping`, `System: Uptime`).
- Ujednolicony schemat tagów: wszędzie `component` + `scope`, a na itemach i triggerach portów dodatkowo `interface: <port>` (zastępuje `target` i `class`).
- Itemy tekstowe zmienione na Character.
- *Interface is down*: High → Average, można go wyłączyć dla portu makrem `{$IFCONTROL:"portN"}`.
- Triggery odrzuceń, błędów i nieznanych protokołów: progi zaszyte na sztywno → makra kontekstowe.
- *VLAN Mismatch or Unknown Protocol detected* przemianowany na neutralny *Unknown protocol frames received* (Information).

---

### v1 – 06.01.2026

#### 🚀 Duża Aktualizacja: Dashboard "Enterprise Light" i standardy Zabbix 7.4

**Data:** 06.01.2026
**Wersja Zabbix:** 7.4+

Ta aktualizacja wprowadza całkowitą przebudowę warstwy wizualnej (Dashboard) oraz standaryzację konfiguracji pod kątem Zabbix 7.x. Szablon ewoluował z prostego zbierania danych do narzędzia diagnostycznego klasy NOC.

#### ✨ Główne Zmiany

**1. Nowy Dashboard "Enterprise Light"**

Zastąpiono standardowe wykresy nowoczesnymi widgetami Honeycomb z paletą kolorów "Material Design".

- **Wysoka czytelność:** Zastosowano pastelowe tła (np. #E8F5E9) i ciemne fonty, zapewniając idealny kontrast wartości.
- **Separacja warstw:** Rozdzielono diagnostykę fizyczną od logicznej:
  - **Status Portów:** Nowy układ hierarchiczny eksponujący dostępność.
  - **Błędy Fizyczne (Physical Errors):** Dedykowany widget pokazujący tylko błędy CRC/fizyczne (uszkodzone kable).
  - **Odrzuty (Packet Drops):** Osobny widget dla zatorów sieciowych i przepełnienia bufora.
  - **Utylizacja Łącza:** Widget z interpolacją kolorów (Zielony -> Żółty -> Czerwony).
  - **Zdrowie Systemu:** Nowa tabela "Top Hosts" agregująca kluczowe wskaźniki (Szum UDP, Błędy logowania, Stres CPU, Opóźnienia Ping).

**2. Wdrożenie Makr Użytkownika**

Usunięto "sztywne" wartości z wyzwalaczy. Od teraz progi alarmowe są konfigurowalne przez Makra:

- `{$IF.UTIL.MAX}` - próg wysycenia łącza (domyślnie 85%).
- `{$NET.UDP.NOISE.MAX}` - próg szumu sieciowego UDP.
- `{$IF.BCAST.MAX.WARN}` - próg burzy broadcast.
- `{$IF.SPEED.MIN}` - oczekiwana prędkość portu.

**3. Nowe Metryki i Logika**

- **ICMP Response Time:** Dodano monitorowanie opóźnień (Ping Latency) niezależnie od SNMP, jako wczesne ostrzeganie przed przeciążeniem.
- **Optymalizacja:** Zastosowano preprocessing Discard unchanged with heartbeat (1d) dla inwentarza i statusów, co znacznie redukuje przyrost bazy danych.

**4. Standaryzacja (Zabbix 7.x)**

- **Tagowanie:** Wdrożono pełny standard tagowania zgodny z nowoczesnymi filtrami:
  - `target: interface` vs `target: device`
  - `scope: health` vs `scope: performance`
