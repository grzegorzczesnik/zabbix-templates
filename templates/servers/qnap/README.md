Zabbix Template: QNAP TVS-473e (SNMP)

[!IMPORTANT]
Release Candidate (RC 1.0)
This is a candidate version of the template. While it is fully functional, it is currently in the testing phase. Please report any issues or suggestions.

Overview

This is a Zabbix template designed specifically for the QNAP TVS-473e NAS, utilizing the SNMP agent. It provides comprehensive monitoring of hardware health, performance, storage, and network statistics.

Zabbix Version: 7.4 (Required due to newer widget types like Honeycomb).

Features

System Monitoring

CPU: Usage (%), Temperature (°C).
Memory: Total and Free memory.
System: Model name, Serial number, Firmware version (with change detection), System Temperature.
Uptime: Monitoring of System, Hardware, and Network uptime.

Low-Level Discovery (LLD)

The template automatically discovers the following components:

Physical Drives:

Capacity, Temperature, Drive Type (HDD/SSD/NVMe).
SMART Status (Normalized to Good/Warning/Error).
"Is Global Spare" status.

Logical Volumes:

Total size and Free space.
Triggers for low and critically low free space.

RAID Groups:

RAID Level and Status (e.g., Ready, Degraded).

Network Interfaces:

Incoming/Outgoing traffic, Errors, Discards.
Interface Speed, Operational Status, MAC Address.

Fans:

Fan speed (RPM) with low-speed alerts.

System Components:

Internal slots/sensors temperature.

Power Supply:

Note: Disabled by default in the template as this model usually relies on an external block or single PSU, but the rule is present.

Installation

QNAP Configuration:
Log in to your QNAP NAS.
Go to Control Panel > Network & File Services > SNMP.
Enable the SNMP Service (select SNMP V1/V2c).
Set a Community string (e.g., public or a custom one).
Apply settings.

Zabbix Configuration:

Download the SNMP QNAP TVS-473e.yaml file.
Go to Data collection > Templates > Import.
Select the file and import.
Create a Host for your QNAP NAS.
Add the SNMP interface (IP address of the NAS, Port 161).
Set the {$SNMP.COMMUNITY} macro on the host (if not using the global default).
Link the template: SNMP QNAP TVS-473e.

Macros & Customization

You can adjust the following macros to tune the alerting thresholds:

Macro	Default	Description

{$CPU.UTIL.CRIT}	90	Critical CPU utilization threshold (%) for 5 minutes.
{$TEMP.CPU.CRIT}	85	Critical CPU temperature threshold (°C).
{$TEMP.DISK.WARN}	55	Warning threshold for Disk temperature (°C).
{$TEMP.DISK.CRIT}	65	Critical threshold for Disk temperature (°C).
{$NET.IF.IFNAME.MATCHES}	^eth[0-3]+$	Regular expression to match specific interfaces (Physical ports).
{$NET.IF.IFNAME.NOT_MATCHES}	(veth|vnet|docker|lo|lxc|qvs|dummy)	Filter to exclude virtual interfaces.

Dashboard

The template includes a pre-configured dashboard "QNAP TVS-473e Overview" featuring:
Honeycomb widgets: For physical disk SMART status and Network Port status.
Gauges: CPU Usage, CPU Temp, System Temp, Memory Usage.
Graphs: Network traffic, Disk temperatures, Fan speeds.
Top Items: Logical volumes with the lowest free space.


Zabbix Szablon: QNAP TVS-473e (SNMP)

[!IMPORTANT]
Wersja Kandydująca (RC 1.0)
Jest to wersja kandydująca (Release Candidate) szablonu. Mimo że jest w pełni funkcjonalna, znajduje się obecnie w fazie testów. Proszę o zgłaszanie wszelkich błędów lub sugestii.

Przegląd
Szablon Zabbix przeznaczony do monitorowania serwera NAS QNAP TVS-473e przy użyciu agenta SNMP. Zapewnia szczegółowy wgląd w stan sprzętu, wydajność, pamięć masową oraz statystyki sieciowe.
Wersja Zabbix: 7.4 (Wymagana ze względu na wykorzystanie nowych typów widżetów, np. Honeycomb).

Funkcjonalności

Monitorowanie Systemu

Procesor (CPU): Użycie (%), Temperatura (°C).
Pamięć RAM: Całkowita i wolna pamięć.
System: Model urządzenia, Numer seryjny, Wersja Firmware (z wykrywaniem zmian), Temperatura systemu.
Uptime: Czas pracy systemu, warstwy sprzętowej oraz sieciowej.
Wykrywanie Niskopoziomowe (LLD)

Szablon automatycznie wykrywa następujące komponenty:

Dyski fizyczne:

Pojemność, Temperatura, Typ dysku (HDD/SSD/NVMe).
Status SMART (Znormalizowany: Good/Warning/Error).
Status "Global Spare".

Woluminy logiczne:

Rozmiar całkowity i wolna przestrzeń.
Alarmy dla niskiego i krytycznie niskiego miejsca.

Grupy RAID:

Poziom RAID i Status (np. Ready, Degraded).

Interfejsy sieciowe:

Ruch przychodzący/wychodzący, błędy, odrzucone pakiety.
Prędkość interfejsu, status operacyjny, adres MAC.

Wentylatory:

Prędkość obrotowa (RPM) wraz z alarmem o niskich obrotach/zatrzymaniu.

Komponenty systemowe:

Temperatury wewnętrznych slotów/czujników.

Zasilanie:

Uwaga: Reguła jest domyślnie wyłączona w szablonie, ponieważ ten model zazwyczaj nie raportuje zasilaczy w standardowy sposób (lub posiada zewnętrzny zasilacz).
Instalacja

Konfiguracja QNAP:

Zaloguj się do QNAP.
Przejdź do Panel Sterowania > Usługi sieciowe i plików > SNMP.
Włącz usługę SNMP (wybierz SNMP V1/V2c).
Ustaw nazwę społeczności (Community), np. public.
Zapisz zmiany.

Konfiguracja Zabbix:

Pobierz plik SNMP QNAP TVS-473e.yaml.
W Zabbix przejdź do Data collection > Templates > Import.
Wybierz plik i zaimportuj go.
Utwórz Hosta dla swojego QNAPa.
Dodaj interfejs SNMP (adres IP NAS-a, Port 161).
Ustaw makro {$SNMP.COMMUNITY} na hoście (jeśli jest inne niż domyślne).
Podepnij szablon: SNMP QNAP TVS-473e.

Makra i Konfiguracja

Możesz dostosować poniższe makra, aby zmienić progi alarmowania:
Makro	Domyślnie	Opis

{$CPU.UTIL.CRIT}	90	Próg krytyczny zużycia procesora (%) przez 5 minut.
{$TEMP.CPU.CRIT}	85	Próg krytyczny temperatury procesora (°C).
{$TEMP.DISK.WARN}	55	Próg ostrzegawczy temperatury dysków (°C).
{$TEMP.DISK.CRIT}	65	Próg krytyczny temperatury dysków (°C).
{$NET.IF.IFNAME.MATCHES}	^eth[0-3]+$	Wyrażenie regularne dopasowujące interfejsy fizyczne.
{$NET.IF.IFNAME.NOT_MATCHES}	(veth|vnet|docker|lo|lxc|qvs|dummy)	Filtr wykluczający interfejsy wirtualne/kontenerowe.

Dashboard

Szablon zawiera gotowy pulpit nawigacyjny "QNAP TVS-473e Overview", który zawiera:
Widżety Honeycomb: Status SMART dysków oraz status portów sieciowych.
Zegary (Gauges): Użycie CPU, Temperatura CPU, Temperatura Systemu, Pamięć.
Wykresy: Ruch sieciowy, Temperatury dysków, Prędkości wentylatorów.
Top Items: Woluminy z najmniejszą ilością wolnego miejsca.
