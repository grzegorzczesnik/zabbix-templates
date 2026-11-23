# Changelog — OpenSSH Debian by Zabbix agent 2 active

## [1.0.0] - 2026-11-23

### EN

First public release.

#### Features
- Effective sshd configuration read from `sshd -T` (includes `sshd_config.d/*.conf` and built-in defaults) via a single master item `ssh.config.effective`; PermitRootLogin, PasswordAuthentication and PermitEmptyPasswords as dependent items; a trigger when `sshd -T` fails (configuration error or missing sudo rule) and when the effective configuration changes.
- Triggers for `PermitRootLogin yes`, `PermitEmptyPasswords yes` and (disabled by default) `PasswordAuthentication yes`.
- Port discovery from `sshd -T` (all ports); port availability and SSH banner time as simple checks from the Zabbix server/proxy; port triggers depend on the listener trigger.
- sshd listener process check `proc.num[sshd,root,,listener]`, working with OpenSSH 9.x and 10.x (`sshd-session`); number of SSH connections counted as `[priv]` processes.
- Successful and failed password logins from `/var/log/auth.log`; brute-force detection with `count()` over 5 minutes, closed automatically after 5 minutes without failures.
- SHA-256 checksum and permissions of `sshd_config`; detection of configuration changed but not reloaded (also `sshd_config.d/*.conf`).
- Host key discovery (all HostKey entries) with permission checks (Disaster, manual close allowed).
- Installed `openssh-server` version, list of logged-in users.
- All agent items active; thresholds in macros; EN/PL descriptions; tags `service`/`component`/`scope`.
- Host preparation script `scripts/openssh-debian-agent2-host-setup.sh` with `--check` mode.

#### Tested
- 2026-11-21 to 2026-11-23 on Debian 12 (OpenSSH 9.2): 11 acceptance tests TC-01 to TC-11, all OK.
- 2026-11-23: deployed on all monitored hosts (Debian 12 and 13).

### PL

Pierwsze publiczne wydanie.

#### Funkcje
- Efektywna konfiguracja sshd z `sshd -T` (z `sshd_config.d/*.conf` i wartościami domyślnymi) przez jeden item główny `ssh.config.effective`; PermitRootLogin, PasswordAuthentication i PermitEmptyPasswords jako itemy zależne; trigger, gdy `sshd -T` zawodzi (błąd konfiguracji albo brak reguły sudo) i gdy zmienia się efektywna konfiguracja.
- Triggery dla `PermitRootLogin yes`, `PermitEmptyPasswords yes` i (domyślnie wyłączony) `PasswordAuthentication yes`.
- Discovery portów z `sshd -T` (wszystkie porty); dostępność portu i czas bannera SSH jako simple checki z serwera/proxy Zabbix; triggery portów zależne od triggera procesu.
- Kontrola procesu nasłuchującego `proc.num[sshd,root,,listener]`, działająca z OpenSSH 9.x i 10.x (`sshd-session`); liczba połączeń SSH liczona jako procesy `[priv]`.
- Udane i nieudane logowania hasłem z `/var/log/auth.log`; wykrywanie brute-force przez `count()` z 5 minut, zamykane automatycznie po 5 minutach bez nieudanych prób.
- Suma SHA-256 i uprawnienia `sshd_config`; wykrywanie zmiany konfiguracji bez przeładowania (także `sshd_config.d/*.conf`).
- Discovery kluczy hosta (wszystkie wpisy HostKey) z kontrolą uprawnień (Disaster, możliwe ręczne zamknięcie).
- Wersja pakietu `openssh-server`, lista zalogowanych użytkowników.
- Wszystkie itemy agenta aktywne; progi w makrach; opisy EN/PL; tagi `service`/`component`/`scope`.
- Skrypt przygotowania hosta `scripts/openssh-debian-agent2-host-setup.sh` z trybem `--check`.

#### Testy
- 2026-11-21 – 2026-11-23 na Debianie 12 (OpenSSH 9.2): 11 testów akceptacyjnych TC-01 – TC-11, wszystkie OK.
- 2026-11-23: wdrożony na wszystkich monitorowanych hostach (Debian 12 i 13).
