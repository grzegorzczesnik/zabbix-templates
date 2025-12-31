SNMP D-Link DGS-1100-08 – Zabbix Template
🇬🇧 English
📌 Overview

This repository contains a Zabbix SNMP template for monitoring the D-Link DGS-1100-08 managed switch.

The template is designed for Zabbix 7.4 and uses SNMP to collect performance, availability, and interface-related metrics. It also includes calculated items and triggers to help detect CPU overload and packet loss symptoms.

🧩 Features

SNMP-based monitoring for D-Link DGS-1100-08

ICMP-based availability and packet loss analysis

Calculated items (e.g. ICMP drop ratio – CPU stress indicator)

Interface statistics monitoring

Ready-to-use triggers

Organized under Templates / Network devices

⚙️ Requirements

Zabbix Server / Proxy 7.4 or newer

D-Link DGS-1100-08 switch

SNMP enabled on the switch

SNMP community (SNMPv1/v2c) or SNMP credentials configured

📥 Installation

Download the file:

SNMP D-Link DGS-1100-08.yaml


In Zabbix Web UI go to:

Data collection → Templates

Click Import

Select the .yaml file and import it

Assign the template SNMP D-Link DGS-1100-08 to your host

🛠 Configuration

Make sure SNMP is enabled on the switch

Configure SNMP interface on the host in Zabbix

Set the correct SNMP community / credentials

Ensure the host has a valid IP or DNS name

📊 Monitored Data (Examples)

ICMP echo requests / replies

ICMP drop ratio (calculated)

Interface traffic and statistics

Device availability

CPU stress symptoms (indirect detection)

🧪 Tested With

Zabbix 7.4

D-Link DGS-1100-08 (Smart Managed Switch)

👤 Author

grzegorz.czesnik@hotmail.com

grzegorz@net59.pl

----------------------------

🇵🇱 Polski
📌 Opis

Repozytorium zawiera szablon Zabbix (SNMP) do monitorowania przełącznika D-Link DGS-1100-08.

Szablon jest przygotowany dla Zabbix 7.4 i wykorzystuje SNMP do zbierania danych o wydajności, dostępności oraz interfejsach sieciowych. Zawiera również elementy obliczeniowe i wyzwalacze pomagające wykrywać przeciążenie CPU oraz utratę pakietów.

🧩 Funkcje

Monitoring SNMP dla D-Link DGS-1100-08

Sprawdzanie dostępności ICMP

Elementy obliczeniowe (np. współczynnik gubienia pingów – wskaźnik obciążenia CPU)

Monitoring portów i statystyk interfejsów

Gotowe wyzwalacze (triggers)

Przypisanie do grupy Templates / Network devices

⚙️ Wymagania

Zabbix Server / Proxy 7.4 lub nowszy

Przełącznik D-Link DGS-1100-08

Włączony SNMP na przełączniku

Skonfigurowana community SNMP (v1/v2c) lub dane SNMP

📥 Instalacja

Pobierz plik:

SNMP D-Link DGS-1100-08.yaml


W interfejsie Zabbix przejdź do:

Zbieranie danych → Szablony

Kliknij Importuj

Wskaż plik .yaml

Przypisz szablon SNMP D-Link DGS-1100-08 do hosta

🛠 Konfiguracja

Upewnij się, że SNMP jest włączony na switchu

Skonfiguruj interfejs SNMP na hoście w Zabbix

Ustaw poprawną community SNMP

Sprawdź poprawność adresu IP / DNS hosta

📊 Monitorowane dane (przykłady)

ICMP echo request / reply

Współczynnik gubienia pakietów ICMP (element obliczeniowy)

Ruch i statystyki portów

Dostępność urządzenia

Pośrednia detekcja przeciążenia CPU

🧪 Testowane

Zabbix 7.4

D-Link DGS-1100-08 (Smart Managed Switch)

👤 Autor

grzegorz.czesnik@hotmail.com

grzegorz@net59.pl
