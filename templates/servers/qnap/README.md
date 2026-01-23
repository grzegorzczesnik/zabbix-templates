# Zabbix Template: QNAP TVS-473e (SNMP)

![Zabbix](https://img.shields.io/badge/Zabbix-7.4+-d00000?style=flat-square&logo=zabbix) ![QNAP](https://img.shields.io/badge/Device-QNAP_TVS--473e-007ebc?style=flat-square&logo=qnap) ![Version](https://img.shields.io/badge/Version-RC_1.0-orange?style=flat-square)

<div align="center">

**Choose your language / Wybierz język**

[🇬🇧 English Description](#-english-description) &nbsp;&nbsp;|&nbsp;&nbsp; [🇵🇱 Polski Opis](#-polski-opis)

</div>

---

<a name="-english-description"></a>
## 🇬🇧 English Description

This is a comprehensive Zabbix template designed for the **QNAP TVS-473e** NAS, utilizing the SNMP agent. It provides detailed monitoring of hardware health, performance metrics, and storage status.

### 📢 Version & Feedback
**Current Version: RC 1.0**
> This is a **Release Candidate**. Your feedback, comments, and bug reports are highly appreciated to help improve this template.
>
> 📧 **Contact & Suggestions:** Please send your feedback to **grzegorz@net59.pl** or feel free to open an issue / submit a pull request here on GitHub.

### ✨ Key Features

* **🖥️ System Performance:**
    * CPU Utilization & Temperature monitoring.
    * System Uptime (Hardware, Network, SNMP).
    * Memory Usage (Free/Total).
* **💾 Storage & RAID:**
    * **Physical Disks:** SMART status (Good/Warning/Error), Temperature, Capacity, Drive Type (detected via regex).
    * **RAID Groups:** Current Level and Status.
    * **Logical Volumes:** Free space percentage and Total size (supports TB/GB/MB conversion).
* **❄️ Cooling & Hardware:**
    * **Fans:** Speed (RPM) monitoring with low-speed alerts.
    * **System Components:** Temperature and Serial Numbers.
    * *Note: Power Supply (PSU) discovery is present but disabled by default for this model.*
* **🌐 Network:**
    * Traffic (In/Out), Discards, Errors, Speed, and MAC address for physical interfaces (filters out virtual adapters).
* **📊 Dashboard:**
    * Includes a built-in dashboard **"QNAP TVS-473e Overview"** visualizing disk health, network traffic, CPU load, and thermal status.

### ⚙️ Configuration & Macros

The template uses the following macros to define alert thresholds. You can customize these in the host configuration:

| Macro | Default | Description |
| :--- | :--- | :--- |
| `{$CPU.UTIL.CRIT}` | **90**% | Critical threshold for CPU utilization (5m average). |
| `{$TEMP.CPU.CRIT}` | **85**°C | Critical threshold for CPU temperature. |
| `{$TEMP.DISK.CRIT}` | **65**°C | Critical temperature for physical disks (failure risk). |
| `{$TEMP.DISK.WARN}` | **55**°C | Warning temperature for physical disks. |
| `{$NET.IF.IFNAME.MATCHES}` | `^eth[0-3]+$` | Regex to match physical interfaces only. |

### 🚀 Installation

1.  Enable **SNMP v1/v2c** or **v3** on your QNAP device via QTS Control Panel.
2.  Download the `yaml` template file.
3.  In Zabbix, go to **Data collection** → **Templates** → **Import**.
4.  Select the file and enable "Create new" for Template groups if necessary.
5.  Assign the template **"SNMP QNAP TVS-473e"** to your QNAP host.

---

<a name="-polski-opis"></a>
## 🇵🇱 Polski Opis

To kompleksowy szablon Zabbix przygotowany dla serwerów NAS **QNAP TVS-473e**, wykorzystujący agenta SNMP. Zapewnia szczegółowy monitoring stanu sprzętu, wydajności oraz statusu dysków.

### 📢 Wersja i Uwagi
**Obecna wersja: RC 1.0**
> Jest to wersja **Release Candidate**. Wszelkie uwagi, sugestie oraz zgłoszenia błędów są bardzo mile widziane i pomogą w ulepszeniu tego szablonu.
>
> 📧 **Kontakt i Sugestie:** Proszę o przesyłanie uwag na adres **grzegorz@net59.pl** lub zgłaszanie ich poprzez system Issues na GitHubie.

### ✨ Główne funkcje

* **🖥️ Wydajność Systemu:**
    * Użycie i temperatura procesora.
    * Czas działania (Uptime) systemu, sprzętu i sieci.
    * Użycie pamięci RAM (Wolna/Całkowita).
* **💾 Pamięć masowa i RAID:**
    * **Dyski fizyczne:** Status SMART (Good/Warning/Error), Temperatura, Pojemność, Typ dysku.
    * **Grupy RAID:** Poziom i status macierzy.
    * **Wolumeny logiczne:** Procent wolnego miejsca i całkowity rozmiar (automatyczna konwersja TB/GB/MB).
* **❄️ Chłodzenie i Sprzęt:**
    * **Wentylatory:** Prędkość obrotowa (RPM) z alarmem przy zatrzymaniu lub niskich obrotach.
    * **Komponenty:** Temperatury i Numery Seryjne.
    * *Uwaga: Wykrywanie zasilaczy (PSU) jest domyślnie wyłączone dla tego modelu.*
* **🌐 Sieć:**
    * Ruch przychodzący/wychodzący, błędy, odrzucone pakiety, prędkość i adresy MAC dla interfejsów fizycznych (filtrowanie adapterów wirtualnych).
* **📊 Dashboard:**
    * Zawiera wbudowany pulpit **"QNAP TVS-473e Overview"** wizualizujący stan dysków, ruch sieciowy, obciążenie CPU i temperatury.

### ⚙️ Konfiguracja i Makra

Szablon wykorzystuje poniższe makra do definiowania progów alarmowych. Możesz je dostosować w konfiguracji hosta:

| Makro | Domyślnie | Opis |
| :--- | :--- | :--- |
| `{$CPU.UTIL.CRIT}` | **90**% | Próg krytyczny zużycia procesora (średnia z 5 min). |
| `{$TEMP.CPU.CRIT}` | **85**°C | Próg krytyczny temperatury procesora (przegrzanie). |
| `{$TEMP.DISK.CRIT}` | **65**°C | Próg krytyczny temperatury dysków (ryzyko awarii). |
| `{$TEMP.DISK.WARN}` | **55**°C | Próg ostrzegawczy temperatury dysków. |
| `{$NET.IF.IFNAME.MATCHES}` | `^eth[0-3]+$` | Wyrażenie regularne do wykrywania tylko portów fizycznych. |

### 🚀 Instalacja

1.  Włącz **SNMP v1/v2c** lub **v3** na urządzeniu QNAP w Panelu Sterowania QTS.
2.  Pobierz plik szablonu `yaml`.
3.  W Zabbix przejdź do **Data collection** → **Templates** → **Import**.
4.  Wybierz plik i zaznacz opcję tworzenia nowych grup, jeśli to konieczne.
5.  Przypisz szablon **"SNMP QNAP TVS-473e"** do swojego hosta QNAP.

---
<div align="center">
  
<sub><b>Vendor:</b> Grzegorz Cześnik (grzegorz@net59.pl) | <b>Version:</b> RC 1.0</sub>

</div>