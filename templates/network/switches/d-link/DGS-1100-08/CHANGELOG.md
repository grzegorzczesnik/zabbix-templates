English Version
🚀 Major Update: "Enterprise Light" Dashboard & Zabbix 7.4 Standards
Date: 2026-01-06
Zabbix Version: 7.4+
This release introduces a complete overhaul of the visual layer (Dashboard) and standardizes the configuration for Zabbix 7.x. The template has evolved from basic data collection to a professional, NOC-grade diagnostic tool.
✨ Key Changes

1. New "Enterprise Light" Dashboard
Replaced standard graphs with modern Honeycomb widgets utilizing a "Material Design" pastel color palette.
High Readability: Switched to pastel backgrounds (e.g., #E8F5E9) with dark text to ensure contrast and readability of values (0 vs 0%).
Layer Separation: Distinct widgets for different diagnostic layers:
Port Status: Hierarchical layout highlighting availability.
Physical Errors (Cabling): Dedicated widget showing only CRC/Physical errors (identifying bad cabling).
Packet Drops (Discards): Separate widget for network congestion/buffer overflows.
Bandwidth Usage: Gradient color interpolation (Green -> Yellow -> Red).
System Health: New "Top Hosts" table aggregating key metrics (UDP Noise, Auth Fails, CPU Stress, Ping Latency).

2. User Macros Implementation
Hardcoded trigger values have been replaced with flexible User Macros:
{$IF.UTIL.MAX} - Bandwidth utilization threshold (default: 85%).
{$NET.UDP.NOISE.MAX} - UDP network noise threshold.
{$IF.BCAST.MAX.WARN} - Broadcast storm threshold.
{$IF.SPEED.MIN} - Expected port speed.

3. New Metrics & Logic
ICMP Response Time: Added a Simple Check item for latency monitoring (Ping Latency), providing early warning before CPU drops occur.
Optimization: Applied Discard unchanged with heartbeat (1d) preprocessing to inventory and status items to significantly reduce database growth.

4. Standardization (Zabbix 7.x)
Tagging: Full implementation of modern tagging standards for better filtering:
target: interface vs target: device
scope: health vs scope: performance


Polska Wersja
🚀 Duża Aktualizacja: Dashboard "Enterprise Light" i standardy Zabbix 7.4
Data: 06.01.2026
Wersja Zabbix: 7.4+
Ta aktualizacja wprowadza całkowitą przebudowę warstwy wizualnej (Dashboard) oraz standaryzację konfiguracji pod kątem Zabbix 7.x. Szablon ewoluował z prostego zbierania danych do narzędzia diagnostycznego klasy NOC.
✨ Główne Zmiany

1. Nowy Dashboard "Enterprise Light"
Zastąpiono standardowe wykresy nowoczesnymi widgetami Honeycomb z paletą kolorów "Material Design".
Wysoka czytelność: Zastosowano pastelowe tła (np. #E8F5E9) i ciemne fonty, zapewniając idealny kontrast wartości.
Separacja warstw: Rozdzielono diagnostykę fizyczną od logicznej:
Status Portów: Nowy układ hierarchiczny eksponujący dostępność.
Błędy Fizyczne (Physical Errors): Dedykowany widget pokazujący tylko błędy CRC/fizyczne (uszkodzone kable).
Odrzuty (Packet Drops): Osobny widget dla zatorów sieciowych i przepełnienia bufora.
Utylizacja Łącza: Widget z interpolacją kolorów (Zielony -> Żółty -> Czerwony).
Zdrowie Systemu: Nowa tabela "Top Hosts" agregująca kluczowe wskaźniki (Szum UDP, Błędy logowania, Stres CPU, Opóźnienia Ping).

2. Wdrożenie Makr Użytkownika
Usunięto "sztywne" wartości z wyzwalaczy. Od teraz progi alarmowe są konfigurowalne przez Makra:
{$IF.UTIL.MAX} - próg wysycenia łącza (domyślnie 85%).
{$NET.UDP.NOISE.MAX} - próg szumu sieciowego UDP.
{$IF.BCAST.MAX.WARN} - próg burzy broadcast.
{$IF.SPEED.MIN} - oczekiwana prędkość portu.

3. Nowe Metryki i Logika
ICMP Response Time: Dodano monitorowanie opóźnień (Ping Latency) niezależnie od SNMP, jako wczesne ostrzeganie przed przeciążeniem.
Optymalizacja: Zastosowano preprocessing Discard unchanged with heartbeat (1d) dla inwentarza i statusów, co znacznie redukuje przyrost bazy danych.

4. Standaryzacja (Zabbix 7.x)
Tagowanie: Wdrożono pełny standard tagowania zgodny z nowoczesnymi filtrami:
target: interface vs target: device
scope: health vs scope: performance
