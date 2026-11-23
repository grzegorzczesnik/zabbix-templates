# OpenSSH Debian by Zabbix agent 2 active

Version 1.0.0 (2026-11-23) · Zabbix 8.0 · Debian 12 / 13 · Zabbix agent 2 (active)

Author / Autor: Grzegorz Cześnik - grzegorz@net59.pl

[English](#english) · [Polski](#polski)

---

## English

Monitors the OpenSSH server on Debian with Zabbix agent 2 in active mode:

- **availability** — sshd listener process, every port sshd listens on (simple check from the Zabbix server/proxy), SSH banner response time;
- **effective configuration** — read from `sshd -T` (includes `sshd_config.d/*.conf` and built-in defaults): PermitRootLogin, PasswordAuthentication, PermitEmptyPasswords, configuration validity, changes not yet reloaded;
- **logins** — successful and failed password logins from `/var/log/auth.log`, brute-force detection;
- **integrity and permissions** — SHA-256 checksum and permissions of `sshd_config`, permissions of every host private key;
- **inventory** — installed `openssh-server` version, logged-in users, number of SSH connections.

See [CHANGELOG.md](CHANGELOG.md).

### Files

| File | Purpose |
| --- | --- |
| `OpenSSH Debian by Zabbix agent 2 active.yaml` | Template export (Zabbix 8.0) |
| `scripts/openssh-debian-agent2-host-setup.sh` | Host preparation script (recommended) |
| `userparameter_ssh.conf` | Agent UserParameters → `/etc/zabbix/zabbix_agent2.d/` |
| `zabbix-sshd.sudoers` | sudo rule for `sshd -T` → `/etc/sudoers.d/zabbix-sshd` |

### Requirements

- Debian 12 (bookworm) or 13 (trixie), `openssh-server` started by `ssh.service` (not `ssh.socket`);
- Zabbix 8.0, Zabbix agent 2 with `ServerActive` configured; the host interface reachable from the Zabbix server/proxy (simple checks);
- `rsyslog` writing `/var/log/auth.log` with ISO 8601 timestamps (Debian default), `acl` package;
- user `zabbix` allowed to run exactly `/usr/sbin/sshd -T` via sudo.

### Host preparation

Recommended — the script (safe to run repeatedly; changes nothing in Zabbix or in the sshd configuration):

```
sudo bash openssh-debian-agent2-host-setup.sh --check   # checks only
sudo bash openssh-debian-agent2-host-setup.sh           # prepares the host
```

Do not link the template while the summary shows `Errors > 0`.

Manual alternative:

```
sudo apt install rsyslog acl
sudo setfacl -m u:zabbix:r /var/log/auth.log
sudo install -m 0440 -o root -g root zabbix-sshd.sudoers /etc/sudoers.d/zabbix-sshd
sudo visudo -c
sudo install -m 0640 -o root -g zabbix userparameter_ssh.conf /etc/zabbix/zabbix_agent2.d/userparameter_ssh.conf
sudo systemctl restart zabbix-agent2
cd /etc/zabbix && sudo -u zabbix zabbix_agent2 -t ssh.config.effective | head -n 1
```

The last command must print a line containing `port 22` (or your port).

### Linking the template

1. Import `OpenSSH Debian by Zabbix agent 2 active.yaml` (Data collection → Templates → Import).
2. Host → Templates → Link new templates → `OpenSSH Debian by Zabbix agent 2 active` → Update.

`ssh.config.effective` is polled every hour, so dependent items and discovery fill in within about an hour.

### Macros

| Macro | Default | Meaning |
| --- | --- | --- |
| `{$SSH.FAILED.MAX}` | `10` | Failed password logins in 5 minutes above which a brute-force problem is raised |
| `{$SSH.CONN.MAX.WARN}` | `5` | SSH connections above which a warning is raised |
| `{$SSH.RESPONSE.MAX}` | `1.5` | Average SSH banner time (s, 5 min) above which a problem is raised |

### Triggers

| Trigger | Severity |
| --- | --- |
| Host private key {#HOSTKEY} has unsafe permissions | Disaster |
| sshd listener process is not running | High |
| Port {#SSHPORT} is not responding (depends on the listener trigger) | High |
| Possible brute-force: more than {$SSH.FAILED.MAX} failed logins in 5m | High |
| Root login with password is permitted (`PermitRootLogin yes`) | High |
| Empty passwords permitted | High |
| Effective configuration cannot be read (`sshd -T` failed) | High |
| sshd_config has been changed (manual close) | High |
| Port {#SSHPORT} response time is too high | Average |
| Failed login for '{ITEM.VALUE}' | Warning |
| Configuration changed but service not reloaded | Warning |
| Unsafe permissions on sshd_config | Warning |
| More than {$SSH.CONN.MAX.WARN} connections | Warning |
| Password authentication is enabled (disabled by default; enable per host) | Warning |
| Successful password login by '{ITEM.VALUE}' | Information |
| Effective configuration has changed (manual close) | Information |
| OpenSSH server package has been changed | Information |

### Tags

Every item has `service: ssh`, `component: config | file | log | package | port | process | session` and `scope: availability | audit | capacity | integrity | inventory | performance | security`. Triggers may add `ssh_login` and `attack: brute-force`.

### Known issues

- `sshd -T` shows the global configuration only; `Match` blocks are not evaluated.
- Only `Failed password` lines are counted; with `PasswordAuthentication no`, attacks seen as `Invalid user` / `[preauth]` are not counted.
- Logins within 3 minutes share one "Successful password login" event; the item history lists every login. MobaXterm opens two connections (terminal + SSH-browser), so one login gives two history entries.
- `ssh.config.effective` also stores sshd warnings (stderr), e.g. about host key permissions — this triggers "Effective configuration has changed".
- A newly discovered port that does not respond raises the problem after the first failed check, not after three.
- Prototype changes reach hosts at the next discovery run (within about 1 hour).
- `/run/sshd.pid` refresh on reload confirmed on OpenSSH 9.2 (Debian 12); on OpenSSH 10 (Debian 13) not yet confirmed.

---

## Polski

Monitoruje serwer OpenSSH na Debianie przez Zabbix agent 2 w trybie aktywnym:

- **dostępność** — proces nasłuchujący sshd, każdy port, na którym nasłuchuje sshd (simple check z serwera/proxy Zabbix), czas odpowiedzi bannera SSH;
- **efektywna konfiguracja** — odczyt z `sshd -T` (z `sshd_config.d/*.conf` i wartościami domyślnymi): PermitRootLogin, PasswordAuthentication, PermitEmptyPasswords, poprawność konfiguracji, zmiany nieprzeładowane;
- **logowania** — udane i nieudane logowania hasłem z `/var/log/auth.log`, wykrywanie brute-force;
- **integralność i uprawnienia** — suma SHA-256 i uprawnienia `sshd_config`, uprawnienia każdego klucza prywatnego hosta;
- **inwentaryzacja** — wersja pakietu `openssh-server`, zalogowani użytkownicy, liczba połączeń SSH.

Zobacz [CHANGELOG.md](CHANGELOG.md).

### Pliki

| Plik | Przeznaczenie |
| --- | --- |
| `OpenSSH Debian by Zabbix agent 2 active.yaml` | Eksport szablonu (Zabbix 8.0) |
| `scripts/openssh-debian-agent2-host-setup.sh` | Skrypt przygotowania hosta (zalecany) |
| `userparameter_ssh.conf` | UserParametery agenta → `/etc/zabbix/zabbix_agent2.d/` |
| `zabbix-sshd.sudoers` | Reguła sudo dla `sshd -T` → `/etc/sudoers.d/zabbix-sshd` |

### Wymagania

- Debian 12 (bookworm) lub 13 (trixie), `openssh-server` uruchamiany przez `ssh.service` (nie `ssh.socket`);
- Zabbix 8.0, Zabbix agent 2 ze skonfigurowanym `ServerActive`; interfejs hosta osiągalny z serwera/proxy Zabbix (simple checki);
- `rsyslog` zapisujący `/var/log/auth.log` ze znacznikami czasu ISO 8601 (domyślnie w Debianie), pakiet `acl`;
- użytkownik `zabbix` może przez sudo wykonać wyłącznie `/usr/sbin/sshd -T`.

### Przygotowanie hosta

Zalecane — skrypt (można uruchamiać wielokrotnie; nie zmienia niczego w Zabbixie ani w konfiguracji sshd):

```
sudo bash openssh-debian-agent2-host-setup.sh --check   # tylko sprawdzenie
sudo bash openssh-debian-agent2-host-setup.sh           # przygotowanie
```

Nie podłączaj szablonu, dopóki podsumowanie pokazuje `Błędów > 0`.

Wariant ręczny:

```
sudo apt install rsyslog acl
sudo setfacl -m u:zabbix:r /var/log/auth.log
sudo install -m 0440 -o root -g root zabbix-sshd.sudoers /etc/sudoers.d/zabbix-sshd
sudo visudo -c
sudo install -m 0640 -o root -g zabbix userparameter_ssh.conf /etc/zabbix/zabbix_agent2.d/userparameter_ssh.conf
sudo systemctl restart zabbix-agent2
cd /etc/zabbix && sudo -u zabbix zabbix_agent2 -t ssh.config.effective | head -n 1
```

Ostatnie polecenie musi wypisać linię z `port 22` (albo Twoim portem).

### Podłączenie szablonu

1. Zaimportuj `OpenSSH Debian by Zabbix agent 2 active.yaml` (Data collection → Templates → Import).
2. Host → Templates → Link new templates → `OpenSSH Debian by Zabbix agent 2 active` → Update.

`ssh.config.effective` jest odpytywany co godzinę, więc itemy zależne i discovery wypełnią się w ciągu ok. godziny.

### Makra

| Makro | Domyślnie | Znaczenie |
| --- | --- | --- |
| `{$SSH.FAILED.MAX}` | `10` | Liczba nieudanych logowań hasłem w 5 minut, powyżej której powstaje problem brute-force |
| `{$SSH.CONN.MAX.WARN}` | `5` | Liczba połączeń SSH, powyżej której powstaje ostrzeżenie |
| `{$SSH.RESPONSE.MAX}` | `1.5` | Średni czas bannera SSH (s, 5 min), powyżej którego powstaje problem |

### Triggery

| Trigger | Ważność |
| --- | --- |
| Host private key {#HOSTKEY} has unsafe permissions | Disaster |
| sshd listener process is not running | High |
| Port {#SSHPORT} is not responding (zależny od triggera procesu) | High |
| Possible brute-force: more than {$SSH.FAILED.MAX} failed logins in 5m | High |
| Root login with password is permitted (`PermitRootLogin yes`) | High |
| Empty passwords permitted | High |
| Effective configuration cannot be read (`sshd -T` zakończone błędem) | High |
| sshd_config has been changed (zamykany ręcznie) | High |
| Port {#SSHPORT} response time is too high | Average |
| Failed login for '{ITEM.VALUE}' | Warning |
| Configuration changed but service not reloaded | Warning |
| Unsafe permissions on sshd_config | Warning |
| More than {$SSH.CONN.MAX.WARN} connections | Warning |
| Password authentication is enabled (domyślnie wyłączony; włączaj na hoście) | Warning |
| Successful password login by '{ITEM.VALUE}' | Information |
| Effective configuration has changed (zamykany ręcznie) | Information |
| OpenSSH server package has been changed | Information |

### Tagi

Każdy item ma `service: ssh`, `component: config | file | log | package | port | process | session` i `scope: availability | audit | capacity | integrity | inventory | performance | security`. Triggery mogą dodawać `ssh_login` i `attack: brute-force`.

### Znane problemy

- `sshd -T` pokazuje tylko konfigurację globalną; bloki `Match` nie są uwzględniane.
- Liczone są tylko linie `Failed password`; przy `PasswordAuthentication no` ataki widoczne jako `Invalid user` / `[preauth]` nie są liczone.
- Logowania w ciągu 3 minut dzielą jedno zdarzenie „Successful password login”; historia itemu zawiera każde logowanie. MobaXterm otwiera dwa połączenia (terminal + SSH-browser), więc jedno logowanie daje dwa wpisy w historii.
- `ssh.config.effective` zapisuje też ostrzeżenia sshd (stderr), np. o uprawnieniach klucza hosta — wywołuje to „Effective configuration has changed”.
- Nowo wykryty port, który nie odpowiada, daje problem po pierwszym nieudanym sprawdzeniu, a nie po trzech.
- Zmiany w prototypach docierają na hosty przy kolejnym przebiegu discovery (w ciągu ok. 1 godziny).
- Odświeżanie `/run/sshd.pid` przy reloadzie potwierdzone na OpenSSH 9.2 (Debian 12); na OpenSSH 10 (Debian 13) jeszcze niepotwierdzone.
