# SNMP D-Link DGS-1100-08 – Zabbix Template

**Version:** 2 (2026-10-24) · **Zabbix:** 7.4 · **Protocol:** SNMPv2c

---

## 🇬🇧 English

### 📌 Overview

Zabbix SNMP template for the **D-Link DGS-1100-08** 8-port switch. It monitors availability (ICMP and SNMP), system information with host inventory, SNMP security counters, management-plane statistics and per-port statistics discovered by LLD.

Uses only standard **MIB-II / IF-MIB** objects – no vendor MIB required.

### 🧩 Features

- **Availability** – ICMP ping, packet loss, response time and SNMP agent availability (internal Zabbix item), with trigger dependencies to avoid alert storms.
- **Port discovery (LLD)** – physical Ethernet ports only (filter on `ifType = 6`), 18 metrics per port: status, speed, traffic (64-bit counters), utilization, unicast/non-unicast packets, errors, discards, unknown protocols, MTU, MAC.
- **Per-port thresholds** – every port threshold is a context macro, so a single port can be tuned or silenced on the host without touching the template.
- **Security** – detection of SNMP requests with a wrong community (`snmpInBadCommunityNames`).
- **Host inventory** – Name, Location, Contact and Hardware filled automatically from SNMP.
- **Consistent tagging** – `component`, `scope` and, on port items/triggers, `interface` – problems can be filtered per port.
- **Dashboard** with two pages: *Overview* and *Front panel* (a port-by-port view of status, speed and load).
- Bilingual descriptions (EN + PL) on all items and triggers.

### ⚙️ Requirements

- Zabbix Server / Proxy **7.4**
- D-Link DGS-1100-08 with SNMP enabled (SNMPv2c)
- ICMP reachability from the Zabbix server/proxy to the switch

### 📥 Installation

1. Download `SNMP D-Link DGS-1100-08.yaml`.
2. Zabbix UI: **Data collection → Templates → Import**, select the file, import.
3. Link the template `SNMP D-Link DGS-1100-08` to the switch host.

### 🛠 Host configuration after import

1. **SNMP interface** on the host: IP/DNS of the switch, SNMPv2, correct community.
2. **Inventory**: host → *Inventory* → **Automatic** (fills Name, Location, Contact, Hardware).
3. **Per-port context macros** (host → *Macros*). Port names must match `{#IFNAME}` exactly – on the tested firmware they are `port1` … `port8` (no space):

| Situation | Host macro | Value |
|---|---|---|
| Port with a device that is switched off (PC, laptop) – no "Interface is down" alert | `{$IFCONTROL:"port5"}` | `0` |
| Device that is 100 Mbps by design (e.g. printer) | `{$IF.SPEED.MIN:"port7"}` | `100000000` |
| Earlier utilization warning on the uplink | `{$IF.UTIL.MAX:"port1"}` | e.g. `70` |

4. If you run **Zabbix network discovery** over the switch's subnet with a different SNMP community, exclude the switch IP from the discovery range – otherwise every discovery run counts as an SNMP authentication failure.

### 🔧 Macros

| Macro | Default | Description |
|---|---|---|
| `{$ICMP_LOSS_WARN}` | `20` | ICMP packet loss warning threshold (%) |
| `{$ICMP_RESPONSE_TIME_WARN}` | `0.15` | ICMP response time warning threshold (s) |
| `{$SNMP.TIMEOUT}` | `5m` | Time without SNMP connectivity before alerting |
| `{$SNMP.AUTH.FAIL.MAX}` | `0` | Allowed SNMP authentication failures per hour |
| `{$NET.UDP.NOISE.MAX}` | `50` | UDP datagrams/s to closed ports on the management IP |
| `{$IFCONTROL}` | `1` | 1 = alert when a port goes down, 0 = ignore · context: port |
| `{$IF.SPEED.MIN}` | `1000000000` | Minimum expected link speed (bps) · context: port |
| `{$IF.UTIL.MAX}` | `85` | Bandwidth utilization warning threshold (%) · context: port |
| `{$IF.ERRORS.WARN}` | `2` | Errors per second · context: port |
| `{$IF.DISCARDS.MAX}` | `10` | Inbound discards per second (initial value – tune to your baseline) · context: port |
| `{$IF.BCAST.MAX.WARN}` | `500` | Broadcast/multicast pps suggesting a storm · context: port |
| `{$IF.UNKNOWN.MAX}` | `5` | Unknown-protocol frames per second · context: port |
| `{$IF.FLAP.MAX}` | `3` | Link state changes within 15 minutes regarded as flapping · context: port |

### 🚨 Triggers

**Device**

| Trigger | Severity | Condition |
|---|---|---|
| Availability: Unavailable by ICMP ping | High | No ICMP replies for 3 minutes |
| Availability: No SNMP data collection | Average | SNMP unavailable for `{$SNMP.TIMEOUT}` (depends on ICMP trigger) |
| Performance: High ICMP ping loss | Warning | Loss > `{$ICMP_LOSS_WARN}` % for 5 minutes |
| Performance: High ICMP ping response time | Warning | Average > `{$ICMP_RESPONSE_TIME_WARN}` s over 5 minutes |
| Security: SNMP authentication failures | Warning | Failures in the last hour > `{$SNMP.AUTH.FAIL.MAX}` |
| System: Device has been restarted | Warning | Uptime < 10 minutes |
| Network: High rate of UDP datagrams to closed ports | Information | > `{$NET.UDP.NOISE.MAX}`/s for 5 minutes |

**Per port (LLD)**

| Trigger | Severity | Condition |
|---|---|---|
| Interface is down | Average | Admin up, link down, `{$IFCONTROL}` = 1 |
| Link flapping | Average | > `{$IF.FLAP.MAX}` state changes in 15 minutes |
| High error rate | Warning | In/out errors > `{$IF.ERRORS.WARN}`/s for 5 minutes |
| Link speed lower than expected | Warning | Speed < `{$IF.SPEED.MIN}` while link is up |
| High inbound discard rate | Warning | Discards > `{$IF.DISCARDS.MAX}`/s for 5 minutes |
| Potential broadcast/multicast storm | Warning | Non-unicast > `{$IF.BCAST.MAX.WARN}` pps for 5 minutes |
| High inbound / outbound bandwidth utilization | Warning | > `{$IF.UTIL.MAX}` % for 5 minutes |
| Unknown protocol frames received | Information | > `{$IF.UNKNOWN.MAX}`/s for 5 minutes |

### 📊 Dashboard "D-Link Switch Overview"

- **Overview** – device identity, port status, errors and discards (honeycomb), inbound/outbound utilization, health & security table, per-port traffic graphs.
- **Front panel** – four rows of eight cells, one per port: link status, negotiated speed, inbound load %, outbound load %.

Open it from **Monitoring → Hosts → *switch* → Dashboards**.

### 🏷 Tags

- Template: `service: switch`, `vendor: d-link`
- Items and triggers: `component` (`icmp`, `snmp`, `network`, `system`) and `scope` (`availability`, `performance`, `statistics`, `security`, `inventory`, `health`, `capacity`, `notice`)
- Port items and triggers: additionally `interface: <port name>`

### ⚠️ Known limitations

- `sysUpTime` wraps after about 497 days – this produces a false "Device has been restarted" alert.
- Port status is polled every minute, so link flaps faster than that are not detected.
- `ifInNUcastPkts` / `ifOutNUcastPkts` are deprecated in IF-MIB. After a week of operation check that they return non-zero values on active ports; if not, the storm trigger never fires.
- The SNMP authentication failure counter does not record the source IP. Use the switch log or port mirroring with `tcpdump` to find the source.
- Port items are keyed by `ifDescr`. A firmware upgrade that changes interface names creates new items; old ones are deleted after 30 days.
- The *Front panel* page references items by name and is built for `port1` … `port8`.
- Error counters are polled every 5 minutes, so a single spike can raise the error trigger.

### 🧪 Tested with

- Zabbix 7.4
- D-Link DGS-1100-08 (port names `port1` … `port8`)

### 📝 Changelog

See [CHANGELOG.md](CHANGELOG.md).

### 👤 Author

Grzegorz · grzegorz@net59.pl · grzegorz.czesnik@hotmail.com

---

## 🇵🇱 Polski

### 📌 Opis

Szablon Zabbix (SNMP) dla 8-portowego przełącznika **D-Link DGS-1100-08**. Monitoruje dostępność (ICMP i SNMP), informacje systemowe z wpisem do inwentarza, liczniki bezpieczeństwa SNMP, statystyki płaszczyzny zarządzania oraz statystyki portów wykrywanych przez LLD.

Korzysta wyłącznie ze standardowych **MIB-II / IF-MIB** – nie wymaga MIB producenta.

### 🧩 Funkcje

- **Dostępność** – ICMP ping, utrata pakietów, czas odpowiedzi i dostępność agenta SNMP (item wewnętrzny Zabbixa), z zależnościami triggerów zapobiegającymi lawinie alertów.
- **Wykrywanie portów (LLD)** – tylko fizyczne porty Ethernet (filtr `ifType = 6`), 18 metryk na port: stan, prędkość, ruch (liczniki 64-bitowe), wykorzystanie pasma, pakiety unicast/non-unicast, błędy, odrzucenia, nieznane protokoły, MTU, MAC.
- **Progi per port** – każdy próg portu to makro kontekstowe, więc pojedynczy port dostroisz lub wyciszysz na hoście bez zmian w szablonie.
- **Bezpieczeństwo** – wykrywanie zapytań SNMP ze złym community (`snmpInBadCommunityNames`).
- **Inwentarz hosta** – Name, Location, Contact i Hardware wypełniane automatycznie z SNMP.
- **Spójne tagi** – `component`, `scope`, a na itemach i triggerach portów także `interface` – problemy można filtrować po porcie.
- **Dashboard** z dwiema stronami: *Overview* i *Front panel* (widok port po porcie: stan, prędkość, obciążenie).
- Opisy dwujęzyczne (EN + PL) przy wszystkich itemach i triggerach.

### ⚙️ Wymagania

- Zabbix Server / Proxy **7.4**
- D-Link DGS-1100-08 z włączonym SNMP (SNMPv2c)
- Osiągalność ICMP z serwera/proxy Zabbixa do switcha

### 📥 Instalacja

1. Pobierz `SNMP D-Link DGS-1100-08.yaml`.
2. W Zabbixie: **Zbieranie danych → Szablony → Importuj**, wskaż plik, zaimportuj.
3. Przypisz szablon `SNMP D-Link DGS-1100-08` do hosta switcha.

### 🛠 Konfiguracja hosta po imporcie

1. **Interfejs SNMP** na hoście: IP/DNS switcha, SNMPv2, poprawne community.
2. **Inwentarz**: host → *Inwentarz* → **Automatyczny** (wypełnia Name, Location, Contact, Hardware).
3. **Makra kontekstowe portów** (host → *Makra*). Nazwa portu musi być identyczna z `{#IFNAME}` – na testowanym firmware to `port1` … `port8` (bez spacji):

| Sytuacja | Makro hosta | Wartość |
|---|---|---|
| Port z urządzeniem wyłączanym (PC, laptop) – bez alarmu „Interface is down” | `{$IFCONTROL:"port5"}` | `0` |
| Urządzenie z natury 100 Mbps (np. drukarka) | `{$IF.SPEED.MIN:"port7"}` | `100000000` |
| Wcześniejsze ostrzeżenie o obciążeniu uplinku | `{$IF.UTIL.MAX:"port1"}` | np. `70` |

4. Jeśli masz w Zabbixie **network discovery** obejmujące podsieć switcha z innym community SNMP, wyłącz IP switcha z zakresu – inaczej każdy przebieg discovery liczy się jako błąd uwierzytelnienia SNMP.

### 🔧 Makra

| Makro | Domyślnie | Opis |
|---|---|---|
| `{$ICMP_LOSS_WARN}` | `20` | Próg ostrzegania o utracie pakietów ICMP (%) |
| `{$ICMP_RESPONSE_TIME_WARN}` | `0.15` | Próg ostrzegania o czasie odpowiedzi ICMP (s) |
| `{$SNMP.TIMEOUT}` | `5m` | Czas braku łączności SNMP przed alarmem |
| `{$SNMP.AUTH.FAIL.MAX}` | `0` | Dopuszczalna liczba błędów uwierzytelnienia SNMP na godzinę |
| `{$NET.UDP.NOISE.MAX}` | `50` | Datagramy UDP/s na zamknięte porty IP zarządzającego |
| `{$IFCONTROL}` | `1` | 1 = alarm przy spadku portu, 0 = ignoruj · kontekst: port |
| `{$IF.SPEED.MIN}` | `1000000000` | Minimalna oczekiwana prędkość łącza (bps) · kontekst: port |
| `{$IF.UTIL.MAX}` | `85` | Próg ostrzegania o wykorzystaniu pasma (%) · kontekst: port |
| `{$IF.ERRORS.WARN}` | `2` | Błędy na sekundę · kontekst: port |
| `{$IF.DISCARDS.MAX}` | `10` | Odrzucone pakiety wejściowe na sekundę (wartość startowa – dostroić do bazy) · kontekst: port |
| `{$IF.BCAST.MAX.WARN}` | `500` | Broadcast/multicast pps wskazujący na sztorm · kontekst: port |
| `{$IF.UNKNOWN.MAX}` | `5` | Ramki nieznanych protokołów na sekundę · kontekst: port |
| `{$IF.FLAP.MAX}` | `3` | Liczba zmian stanu łącza w 15 minut uznawana za flapping · kontekst: port |

### 🚨 Triggery

**Urządzenie**

| Trigger | Ważność | Warunek |
|---|---|---|
| Availability: Unavailable by ICMP ping | High | Brak odpowiedzi ICMP przez 3 minuty |
| Availability: No SNMP data collection | Average | SNMP niedostępne przez `{$SNMP.TIMEOUT}` (zależny od triggera ICMP) |
| Performance: High ICMP ping loss | Warning | Utrata > `{$ICMP_LOSS_WARN}` % przez 5 minut |
| Performance: High ICMP ping response time | Warning | Średnia > `{$ICMP_RESPONSE_TIME_WARN}` s z 5 minut |
| Security: SNMP authentication failures | Warning | Błędy z ostatniej godziny > `{$SNMP.AUTH.FAIL.MAX}` |
| System: Device has been restarted | Warning | Uptime < 10 minut |
| Network: High rate of UDP datagrams to closed ports | Information | > `{$NET.UDP.NOISE.MAX}`/s przez 5 minut |

**Per port (LLD)**

| Trigger | Ważność | Warunek |
|---|---|---|
| Interface is down | Average | Port włączony, brak linku, `{$IFCONTROL}` = 1 |
| Link flapping | Average | > `{$IF.FLAP.MAX}` zmian stanu w 15 minut |
| High error rate | Warning | Błędy wej./wyj. > `{$IF.ERRORS.WARN}`/s przez 5 minut |
| Link speed lower than expected | Warning | Prędkość < `{$IF.SPEED.MIN}` przy aktywnym linku |
| High inbound discard rate | Warning | Odrzucenia > `{$IF.DISCARDS.MAX}`/s przez 5 minut |
| Potential broadcast/multicast storm | Warning | Non-unicast > `{$IF.BCAST.MAX.WARN}` pps przez 5 minut |
| High inbound / outbound bandwidth utilization | Warning | > `{$IF.UTIL.MAX}` % przez 5 minut |
| Unknown protocol frames received | Information | > `{$IF.UNKNOWN.MAX}`/s przez 5 minut |

### 📊 Dashboard „D-Link Switch Overview”

- **Overview** – identyfikacja urządzenia, stan portów, błędy i odrzucenia (honeycomb), wykorzystanie pasma wej./wyj., tabela zdrowia i bezpieczeństwa, wykresy ruchu portów.
- **Front panel** – cztery rzędy po osiem komórek, jedna na port: stan łącza, wynegocjowana prędkość, obciążenie wejścia %, obciążenie wyjścia %.

Otwierasz go z poziomu hosta: **Monitoring → Hosts → *switch* → Dashboards** (nazwy menu w angielskim interfejsie).

### 🏷 Tagi

- Szablon: `service: switch`, `vendor: d-link`
- Itemy i triggery: `component` (`icmp`, `snmp`, `network`, `system`) i `scope` (`availability`, `performance`, `statistics`, `security`, `inventory`, `health`, `capacity`, `notice`)
- Itemy i triggery portów: dodatkowo `interface: <nazwa portu>`

### ⚠️ Znane ograniczenia

- `sysUpTime` przekręca się po ok. 497 dniach – daje to fałszywy alarm „Device has been restarted”.
- Stan portu jest odczytywany co minutę, więc szybsze przeskoki łącza nie są wykrywane.
- `ifInNUcastPkts` / `ifOutNUcastPkts` są przestarzałe w IF-MIB. Po tygodniu pracy sprawdź, czy na aktywnych portach mają wartości niezerowe; jeśli nie, trigger sztormu nigdy nie zadziała.
- Licznik błędów uwierzytelnienia SNMP nie zapisuje IP źródła. Do jego ustalenia użyj logu switcha albo port mirroringu i `tcpdump`.
- Itemy portów są oparte na `ifDescr`. Aktualizacja firmware zmieniająca nazwy interfejsów tworzy nowe itemy; stare są usuwane po 30 dniach.
- Strona *Front panel* wskazuje itemy po nazwie i jest zbudowana dla `port1` … `port8`.
- Liczniki błędów są odczytywane co 5 minut, więc pojedynczy skok może wywołać trigger błędów.

### 🧪 Testowane

- Zabbix 7.4
- D-Link DGS-1100-08 (nazwy portów `port1` … `port8`)

### 📝 Historia zmian

Zobacz [CHANGELOG.md](CHANGELOG.md).

### 👤 Autor

Grzegorz · grzegorz@net59.pl · grzegorz.czesnik@hotmail.com
