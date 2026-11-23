#!/bin/bash
# =============================================================================
# openssh-debian-agent2-host-setup.sh
#
# EN: Prepares a Debian 12/13 host for the Zabbix template
#     "OpenSSH Debian by Zabbix agent 2 active" v1.0.0 (see README.md).
# PL: Przygotowuje host Debian 12/13 pod szablon Zabbix
#     "OpenSSH Debian by Zabbix agent 2 active" v1.0.0 (zobacz README.md).
#
# EN: Handles three cases: host not prepared at all, host prepared for the old
#     template "Custom SSH Debian Agent2", host already prepared for 1.0.0
#     (then it only checks and changes nothing).
# PL: Obsługuje trzy sytuacje: host w ogóle nieprzygotowany, host przygotowany
#     pod stary szablon "Custom SSH Debian Agent2", host już przygotowany
#     pod 1.0.0 (wtedy tylko sprawdza i niczego nie zmienia).
#
# EN: Usage / PL: Użycie:
#   sudo bash openssh-debian-agent2-host-setup.sh            # EN: prepare  / PL: przygotowanie
#   sudo bash openssh-debian-agent2-host-setup.sh --check    # EN: check only, no changes
#                                                    # PL: tylko sprawdzenie, bez zmian
#
# EN: Does NOT change anything in Zabbix (GUI) and does NOT touch the sshd
#     configuration. Afterwards link the template to the host in Zabbix.
# PL: NIE zmienia niczego w Zabbixie (GUI) i NIE dotyka konfiguracji sshd.
#     Potem podłącz szablon do hosta w Zabbixie.
#
# Author / Autor:   Grzegorz Cześnik - grzegorz@net59.pl
# Version / Wersja: 1.0.0 (2026-11-23)
# =============================================================================

set -u

CHECK_ONLY=0
if [ "${1:-}" = "--check" ]; then
    CHECK_ONLY=1
fi

UP_FILE="/etc/zabbix/zabbix_agent2.d/userparameter_ssh.conf"
SUDOERS_FILE="/etc/sudoers.d/zabbix-sshd"
AUTH_LOG="/var/log/auth.log"
AGENT_LOG="/var/log/zabbix/zabbix_agent2.log"
STAMP="$(date +%Y%m%d-%H%M%S)"
ERRORS=0
CHANGES=0

# EN: Every message is printed in English, then in Polish on the next line.
# PL: Każdy komunikat jest wypisywany po angielsku, a w następnej linii po polsku.
msg()    { printf '%-9s %s\n' "$1" "$2"; printf '%-9s PL: %s\n' "" "$3"; }
ok()     { msg "[OK]"     "$1" "$2"; }
change() { msg "[CHANGE]" "$1" "$2"; CHANGES=$((CHANGES+1)); }
warn()   { msg "[WARN]"   "$1" "$2"; }
fail()   { msg "[ERROR]"  "$1" "$2"; ERRORS=$((ERRORS+1)); }
step()   { echo; echo "=== $1 / $2 ==="; }
stop()   {
    echo
    msg "[STOP]" "$1" "$2"
    msg ""       "Nothing else was changed." "Nic więcej nie zostało zmienione."
    exit 1
}

# EN: Test a key as user zabbix. Run from /etc/zabbix: the agent config may use relative
#     Include paths (e.g. zabbix_agent2.d/plugins.d/*.conf), resolved against the current
#     directory - from a home directory user zabbix gets "stat .: permission denied".
# PL: Test klucza jako użytkownik zabbix. Uruchamiane z /etc/zabbix: konfiguracja agenta może
#     mieć względne ścieżki Include (np. zabbix_agent2.d/plugins.d/*.conf), liczone od bieżącego
#     katalogu - z katalogu domowego użytkownik zabbix dostaje "stat .: permission denied".
agent_test() { ( cd /etc/zabbix && runuser -u zabbix -- zabbix_agent2 -t "$1" 2>&1 ); }

# -----------------------------------------------------------------------------
step "0. Prerequisites" "Warunki wstępne"
# -----------------------------------------------------------------------------

if [ "$(id -u)" -ne 0 ]; then
    stop "Run with sudo: sudo bash $0" "Uruchom przez sudo: sudo bash $0"
fi

# EN: Backups go to the home directory of the user who ran sudo
# PL: Kopie zapasowe trafiają do katalogu domowego użytkownika, który uruchomił sudo
BACKUP_USER="${SUDO_USER:-root}"
BACKUP_DIR="$(getent passwd "$BACKUP_USER" | cut -d: -f6)"
if [ -z "$BACKUP_DIR" ] || [ ! -d "$BACKUP_DIR" ]; then
    stop "Home directory of $BACKUP_USER not found (needed for backups)." \
         "Nie znaleziono katalogu domowego $BACKUP_USER (potrzebny na kopie zapasowe)."
fi
ok "Backups will be stored in: $BACKUP_DIR" "Kopie zapasowe trafią do: $BACKUP_DIR"

if [ -r /etc/debian_version ]; then
    ok "Debian $(cat /etc/debian_version)" "Debian $(cat /etc/debian_version)"
else
    stop "This is not Debian (/etc/debian_version missing)." \
         "To nie jest Debian (brak /etc/debian_version)."
fi

if ! id zabbix >/dev/null 2>&1; then
    stop "User zabbix does not exist - is Zabbix agent 2 installed?" \
         "Brak użytkownika zabbix - czy Zabbix agent 2 jest zainstalowany?"
fi
if [ ! -d /etc/zabbix/zabbix_agent2.d ]; then
    stop "Directory /etc/zabbix/zabbix_agent2.d missing - is Zabbix agent 2 installed?" \
         "Brak katalogu /etc/zabbix/zabbix_agent2.d - czy Zabbix agent 2 jest zainstalowany?"
fi
if ! command -v zabbix_agent2 >/dev/null 2>&1; then
    stop "Command zabbix_agent2 not found." "Brak polecenia zabbix_agent2."
fi
ok "Zabbix agent 2 is installed" "Zabbix agent 2 jest zainstalowany"

if [ ! -x /usr/sbin/sshd ]; then
    stop "/usr/sbin/sshd missing - is openssh-server installed?" \
         "Brak /usr/sbin/sshd - czy openssh-server jest zainstalowany?"
fi
SSH_VER="$(dpkg-query -W -f='${Version}' openssh-server 2>/dev/null)"
ok "openssh-server $SSH_VER" "openssh-server $SSH_VER"

if ! /usr/sbin/sshd -t >/dev/null 2>&1; then
    stop "sshd -t reports a configuration error. Fix the sshd configuration first (sudo sshd -t)." \
         "sshd -t zgłasza błąd konfiguracji. Najpierw napraw konfigurację sshd (sudo sshd -t)."
fi
ok "sshd -t: configuration is valid" "sshd -t: konfiguracja poprawna"

if systemctl is-active --quiet ssh.socket 2>/dev/null; then
    warn "ssh.socket is active (socket activation) - item S09 (listener) will raise false alarms. Known issue 11." \
         "Aktywny ssh.socket (aktywacja przez gniazdo) - item S09 (listener) będzie dawał fałszywe alarmy. Znany problem 11."
fi

if [ -n "$(ls -A /etc/ssh/sshd_config.d/ 2>/dev/null)" ]; then
    warn "/etc/ssh/sshd_config.d/ contains files - they take precedence over sshd_config:" \
         "W /etc/ssh/sshd_config.d/ są pliki - mają pierwszeństwo przed sshd_config:"
    ls -la /etc/ssh/sshd_config.d/
fi

# -----------------------------------------------------------------------------
step "1. Host state" "Rozpoznanie stanu hosta"
# -----------------------------------------------------------------------------

STATE="none"
if [ -f "$UP_FILE" ]; then
    if grep -q '^UserParameter=ssh.config.effective,' "$UP_FILE"; then
        STATE="current"
    elif grep -q -e '^UserParameter=ssh.failed_logins.last5m,' -e '^UserParameter=ssh.port.discovery,' "$UP_FILE"; then
        STATE="old"
    else
        STATE="unknown"
    fi
fi

case "$STATE" in
    none)    ok   "$UP_FILE not found - host not prepared" \
                  "Brak $UP_FILE - host nieprzygotowany" ;;
    old)     ok   "UserParameter file from the old template (Custom SSH Debian Agent2) found" \
                  "Znaleziono plik UserParameter starego szablonu (Custom SSH Debian Agent2)" ;;
    current) ok   "UserParameter file from version 1.0.0 found" \
                  "Znaleziono plik UserParameter z wersji 1.0.0" ;;
    unknown) warn "$UP_FILE exists but is neither the old template nor 1.0.0 - it will be replaced (with a backup)" \
                  "$UP_FILE istnieje, ale nie jest ani ze starego szablonu, ani 1.0.0 - zostanie zastąpiony (z kopią)" ;;
esac

if [ -f "$SUDOERS_FILE" ]; then
    ok "$SUDOERS_FILE exists" "Istnieje $SUDOERS_FILE"
else
    ok "$SUDOERS_FILE does not exist" "Brak $SUDOERS_FILE"
fi

if [ "$CHECK_ONLY" -eq 1 ]; then
    echo
    echo "Mode --check: checks only, no changes."
    echo "Tryb --check: tylko sprawdzenia, bez zmian."
fi

# -----------------------------------------------------------------------------
step "2. Backup of the current UserParameter file" "Kopia zapasowa obecnego pliku UserParameter"
# -----------------------------------------------------------------------------

BACKUP_FILE=""
if [ -f "$UP_FILE" ] && [ "$STATE" != "current" ]; then
    BACKUP_FILE="$BACKUP_DIR/userparameter_ssh.conf.${STATE}.$STAMP"
    if [ "$CHECK_ONLY" -eq 1 ]; then
        warn "A backup would be created: $BACKUP_FILE" \
             "Zostałaby wykonana kopia: $BACKUP_FILE"
    else
        if cp -p "$UP_FILE" "$BACKUP_FILE"; then
            change "Backup: $BACKUP_FILE" "Kopia: $BACKUP_FILE"
        else
            stop "Backup of $UP_FILE failed." "Nie udało się wykonać kopii $UP_FILE."
        fi
    fi
else
    ok "No backup needed" "Kopia niepotrzebna"
fi

# -----------------------------------------------------------------------------
step "3. Packages rsyslog and acl" "Pakiety rsyslog i acl"
# -----------------------------------------------------------------------------

MISSING=""
for p in rsyslog acl; do
    if dpkg-query -W -f='${Status}' "$p" 2>/dev/null | grep -q "install ok installed"; then
        ok "Package $p is installed" "Pakiet $p zainstalowany"
    else
        MISSING="$MISSING $p"
    fi
done
if [ -n "$MISSING" ]; then
    if [ "$CHECK_ONLY" -eq 1 ]; then
        warn "Missing packages:$MISSING" "Brakuje pakietów:$MISSING"
    else
        # shellcheck disable=SC2086
        if apt-get install -y $MISSING >/dev/null; then
            change "Installed:$MISSING" "Zainstalowano:$MISSING"
        else
            stop "apt-get install$MISSING failed." "apt-get install$MISSING zakończył się błędem."
        fi
    fi
fi

# -----------------------------------------------------------------------------
step "4. Agent access to $AUTH_LOG (ACL)" "Dostęp agenta do $AUTH_LOG (ACL)"
# -----------------------------------------------------------------------------

if [ ! -f "$AUTH_LOG" ] && [ "$CHECK_ONLY" -eq 0 ]; then
    systemctl restart rsyslog
    logger -p auth.info "openssh-debian-agent2-host-setup: auth.log write test"
    sleep 2
fi

if [ ! -f "$AUTH_LOG" ]; then
    if [ "$CHECK_ONLY" -eq 1 ]; then
        warn "$AUTH_LOG does not exist" "Brak $AUTH_LOG"
    else
        fail "$AUTH_LOG does not exist although rsyslog is running - check the rsyslog configuration." \
             "Brak $AUTH_LOG mimo działającego rsyslog - sprawdź konfigurację rsyslog."
    fi
else
    if getfacl -p "$AUTH_LOG" 2>/dev/null | grep -q '^user:zabbix:r'; then
        ok "ACL user:zabbix:r-- already set" "ACL user:zabbix:r-- już ustawiony"
    elif [ "$CHECK_ONLY" -eq 1 ]; then
        warn "No ACL for zabbix on $AUTH_LOG" "Brak ACL dla zabbix na $AUTH_LOG"
    else
        if setfacl -m u:zabbix:r "$AUTH_LOG"; then
            change "ACL user:zabbix:r-- set on $AUTH_LOG" "Ustawiono ACL user:zabbix:r-- na $AUTH_LOG"
        else
            fail "setfacl on $AUTH_LOG failed" "setfacl na $AUTH_LOG nie powiódł się"
        fi
    fi

    if runuser -u zabbix -- head -c 1 "$AUTH_LOG" >/dev/null 2>&1; then
        ok "User zabbix can read $AUTH_LOG" "Użytkownik zabbix może czytać $AUTH_LOG"
    elif [ "$CHECK_ONLY" -eq 1 ]; then
        warn "User zabbix cannot read $AUTH_LOG" "Użytkownik zabbix nie może czytać $AUTH_LOG"
    else
        fail "User zabbix cannot read $AUTH_LOG" "Użytkownik zabbix nie może czytać $AUTH_LOG"
    fi

    FIRST_LINE="$(head -n 1 "$AUTH_LOG" 2>/dev/null)"
    if echo "$FIRST_LINE" | grep -Eq '^[0-9]{4}-[0-9]{2}-[0-9]{2}T'; then
        ok "Timestamp format in $AUTH_LOG: ISO 8601" "Format daty w $AUTH_LOG: ISO 8601"
    elif [ -n "$FIRST_LINE" ]; then
        warn "Timestamp format in $AUTH_LOG is not ISO 8601 - Log time format of items S13/S14 will not match" \
             "Format daty w $AUTH_LOG nie jest ISO 8601 - pole Log time format itemów S13/S14 nie będzie pasować"
    fi
fi

# -----------------------------------------------------------------------------
step "5. sudo permission for sshd -T ($SUDOERS_FILE)" "Uprawnienie sudo dla sshd -T ($SUDOERS_FILE)"
# -----------------------------------------------------------------------------

SUDOERS_CONTENT='# /etc/sudoers.d/zabbix-sshd
# OpenSSH Debian by Zabbix agent 2 active v1.0.0 - odczyt efektywnej konfiguracji sshd
zabbix ALL=(root) NOPASSWD: /usr/sbin/sshd -T'

TMP_SUDOERS="$(mktemp)"
printf '%s\n' "$SUDOERS_CONTENT" > "$TMP_SUDOERS"

if [ -f "$SUDOERS_FILE" ] && cmp -s "$TMP_SUDOERS" "$SUDOERS_FILE"; then
    ok "$SUDOERS_FILE has the expected content" "$SUDOERS_FILE ma właściwą treść"
elif [ "$CHECK_ONLY" -eq 1 ]; then
    warn "$SUDOERS_FILE missing or different - it would be (over)written" \
         "$SUDOERS_FILE brak albo inna treść - zostałby (nad)pisany"
else
    if visudo -cf "$TMP_SUDOERS" >/dev/null; then
        if [ -f "$SUDOERS_FILE" ]; then
            cp -p "$SUDOERS_FILE" "$BACKUP_DIR/zabbix-sshd.sudoers.$STAMP"
        fi
        install -m 0440 -o root -g root "$TMP_SUDOERS" "$SUDOERS_FILE"
        change "Written $SUDOERS_FILE (0440 root:root)" "Zapisano $SUDOERS_FILE (0440 root:root)"
    else
        rm -f "$TMP_SUDOERS"
        stop "visudo rejected the sudoers content - nothing was written." \
             "visudo odrzucił treść pliku sudoers - nic nie zapisano."
    fi
fi
rm -f "$TMP_SUDOERS"

# EN: sudoers files must be 0440 (visudo -f creates 0640 - observed 2026-11-21)
# PL: pliki sudoers muszą mieć 0440 (visudo -f tworzy 0640 - obserwacja z 2026-11-21)
for f in "$SUDOERS_FILE" /etc/sudoers.d/zabbix-firewalld; do
    [ -f "$f" ] || continue
    MODE="$(stat -c %a "$f")"
    if [ "$MODE" = "440" ]; then
        ok "$f has permissions 0440" "$f ma uprawnienia 0440"
    elif [ "$CHECK_ONLY" -eq 1 ]; then
        warn "$f has permissions 0$MODE instead of 0440" "$f ma uprawnienia 0$MODE zamiast 0440"
    else
        chmod 0440 "$f" && change "$f: permissions 0$MODE -> 0440" "$f: uprawnienia 0$MODE -> 0440"
    fi
done

if [ "$CHECK_ONLY" -eq 0 ] || [ -f "$SUDOERS_FILE" ]; then
    if visudo -c >/dev/null 2>&1; then
        ok "visudo -c: all sudoers files are valid" "visudo -c: wszystkie pliki sudoers poprawne"
    else
        fail "visudo -c reports a problem - check: sudo visudo -c" \
             "visudo -c zgłasza problem - sprawdź: sudo visudo -c"
    fi

    if runuser -u zabbix -- sudo -n /usr/sbin/sshd -T 2>/dev/null | grep -q '^port [0-9]'; then
        ok "zabbix can run sudo -n /usr/sbin/sshd -T" "zabbix może wykonać sudo -n /usr/sbin/sshd -T"
    elif [ "$CHECK_ONLY" -eq 1 ]; then
        warn "zabbix cannot run sudo /usr/sbin/sshd -T yet" "zabbix nie może jeszcze wykonać sudo /usr/sbin/sshd -T"
    else
        fail "zabbix cannot run sudo -n /usr/sbin/sshd -T" "zabbix nie może wykonać sudo -n /usr/sbin/sshd -T"
    fi
fi

# -----------------------------------------------------------------------------
step "6. UserParameter file v1.0.0 ($UP_FILE)" "Plik UserParameter v1.0.0 ($UP_FILE)"
# -----------------------------------------------------------------------------

TMP_UP="$(mktemp)"
cat > "$TMP_UP" <<'EOF'
# /etc/zabbix/zabbix_agent2.d/userparameter_ssh.conf
# OpenSSH Debian by Zabbix agent 2 active v1.0.0 (2026-11-23)
# ------------------------------------------------------------

# --- 1. Efektywna konfiguracja sshd ---
# Wymaga /etc/sudoers.d/zabbix-sshd. Z wyniku korzystaja itemy zalezne i reguly LLD.
UserParameter=ssh.config.effective,sudo -n /usr/sbin/sshd -T 2>&1

# --- 2. Sesje i wersja pakietu ---
UserParameter=ssh.sessions.users,who
UserParameter=ssh.package.version,dpkg-query -W -f='${Version}' openssh-server

# --- 3. Zmiana konfiguracji bez przeladowania uslugi ---
# 1 = najnowszy plik konfiguracji jest nowszy niz /run/sshd.pid
UserParameter=ssh.config.pending_reload,[ -f /run/sshd.pid ] || { echo 0; exit; }; conf=$(stat -c %Y /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf 2>/dev/null | sort -n | tail -n 1); pid=$(stat -c %Y /run/sshd.pid); [ "${conf:-0}" -gt "$pid" ] && echo 1 || echo 0
EOF

CUR_TMP="$(mktemp)"
NEW_TMP="$(mktemp)"
UP_CHANGED=0
if [ -f "$UP_FILE" ] \
   && grep -v '^#' "$UP_FILE" | grep -v '^$' > "$CUR_TMP" \
   && grep -v '^#' "$TMP_UP"  | grep -v '^$' > "$NEW_TMP" \
   && cmp -s "$CUR_TMP" "$NEW_TMP"; then
    ok "UserParameter file already has v1.0.0 content (comments ignored)" \
       "Plik UserParameter ma już treść v1.0.0 (komentarze pominięte przy porównaniu)"
elif [ "$CHECK_ONLY" -eq 1 ]; then
    warn "UserParameter file would be replaced with version 1.0.0" \
         "Plik UserParameter zostałby zastąpiony wersją 1.0.0"
else
    install -m 0640 -o root -g zabbix "$TMP_UP" "$UP_FILE"
    change "Written $UP_FILE v1.0.0 (0640 root:zabbix)" "Zapisano $UP_FILE v1.0.0 (0640 root:zabbix)"
    UP_CHANGED=1
fi
rm -f "$TMP_UP" "$CUR_TMP" "$NEW_TMP"

if [ -f "$UP_FILE" ]; then
    PERM="$(stat -c '%a %U:%G' "$UP_FILE")"
    if [ "$PERM" = "640 root:zabbix" ]; then
        ok "Permissions of $UP_FILE: 0640 root:zabbix" "Uprawnienia $UP_FILE: 0640 root:zabbix"
    elif [ "$CHECK_ONLY" -eq 1 ]; then
        warn "Permissions of $UP_FILE: $PERM (expected 640 root:zabbix)" \
             "Uprawnienia $UP_FILE: $PERM (oczekiwane 640 root:zabbix)"
    else
        chown root:zabbix "$UP_FILE" && chmod 0640 "$UP_FILE"
        change "Fixed permissions of $UP_FILE (was: $PERM)" "Poprawiono uprawnienia $UP_FILE (było: $PERM)"
        UP_CHANGED=1
    fi
fi

# -----------------------------------------------------------------------------
step "7. Agent restart" "Restart agenta"
# -----------------------------------------------------------------------------

RESTART_TIME=""

# EN: Restart also when the file is newer than the running agent (e.g. edited by hand,
#     or a previous run was interrupted) - otherwise the agent does not know the keys.
# PL: Restart także wtedy, gdy plik jest nowszy niż działający agent (np. edytowany ręcznie
#     albo poprzednie uruchomienie zostało przerwane) - inaczej agent nie zna kluczy.
if [ "$UP_CHANGED" -eq 0 ] && [ -f "$UP_FILE" ]; then
    AGENT_START="$(systemctl show zabbix-agent2 -p ActiveEnterTimestamp --value 2>/dev/null)"
    AGENT_START_S="$(date -d "$AGENT_START" +%s 2>/dev/null || echo 0)"
    UP_MTIME_S="$(stat -c %Y "$UP_FILE")"
    if [ "$AGENT_START_S" -gt 0 ] && [ "$UP_MTIME_S" -gt "$AGENT_START_S" ]; then
        if [ "$CHECK_ONLY" -eq 1 ]; then
            warn "$UP_FILE is newer than the running agent (started $AGENT_START) - a restart is needed" \
                 "$UP_FILE jest nowszy niż działający agent (start $AGENT_START) - potrzebny restart"
        else
            warn "$UP_FILE is newer than the running agent (started $AGENT_START) - restarting" \
                 "$UP_FILE jest nowszy niż działający agent (start $AGENT_START) - restart"
            UP_CHANGED=1
        fi
    else
        ok "Running agent already uses the current $UP_FILE (agent started $AGENT_START)" \
           "Działający agent używa już aktualnego $UP_FILE (start agenta $AGENT_START)"
    fi
fi

if [ "$UP_CHANGED" -eq 1 ] && [ "$CHECK_ONLY" -eq 0 ]; then
    RESTART_TIME="$(date '+%Y/%m/%d %H:%M:%S')"
    if systemctl restart zabbix-agent2; then
        sleep 3
        if systemctl is-active --quiet zabbix-agent2; then
            change "zabbix-agent2 restarted ($RESTART_TIME)" "Zrestartowano zabbix-agent2 ($RESTART_TIME)"
        else
            fail "zabbix-agent2 is not running after restart - check: systemctl status zabbix-agent2" \
                 "zabbix-agent2 nie działa po restarcie - sprawdź: systemctl status zabbix-agent2"
        fi
    else
        fail "systemctl restart zabbix-agent2 failed" "systemctl restart zabbix-agent2 nie powiódł się"
    fi
elif [ "$UP_CHANGED" -eq 0 ]; then
    ok "No restart needed" "Restart niepotrzebny"
fi

# -----------------------------------------------------------------------------
step "8. UserParameter keys check (zabbix_agent2 -t as zabbix)" "Kontrola kluczy UserParameter (zabbix_agent2 -t jako zabbix)"
# -----------------------------------------------------------------------------

if grep -q '^UserParameter=ssh.config.effective,' "$UP_FILE" 2>/dev/null; then
    OUT="$(agent_test ssh.config.effective | head -n 1)"
    if echo "$OUT" | grep -q 'port [0-9]'; then
        ok "ssh.config.effective: $OUT" "ssh.config.effective: $OUT"
    else
        fail "ssh.config.effective returns: $OUT" "ssh.config.effective zwraca: $OUT"
    fi

    OUT="$(agent_test ssh.config.pending_reload)"
    if echo "$OUT" | grep -Eq '\[s\|[01]\]'; then
        ok "$OUT" "$OUT"
    else
        fail "ssh.config.pending_reload returns: $OUT" "ssh.config.pending_reload zwraca: $OUT"
    fi

    OUT="$(agent_test ssh.package.version)"
    if echo "$OUT" | grep -q '\[s|'; then
        ok "$OUT" "$OUT"
    else
        fail "ssh.package.version returns: $OUT" "ssh.package.version zwraca: $OUT"
    fi

    if agent_test ssh.sessions.users | grep -Eq '\[(s|t)\|'; then
        ok "ssh.sessions.users responds" "ssh.sessions.users odpowiada"
    else
        fail "ssh.sessions.users does not respond" "ssh.sessions.users nie odpowiada"
    fi
elif [ "$CHECK_ONLY" -eq 1 ]; then
    warn "UserParameter file is not version 1.0.0 - key check skipped" \
         "Plik UserParameter nie jest w wersji 1.0.0 - kontrola kluczy pominięta"
else
    fail "UserParameter file is not version 1.0.0 after preparation" \
         "Plik UserParameter nie jest w wersji 1.0.0 po przygotowaniu"
fi

if [ -n "$RESTART_TIME" ] && [ -f "$AGENT_LOG" ]; then
    LOG_ERRORS="$(awk -v t="$RESTART_TIME" 'substr($0,1,19) >= t' "$AGENT_LOG" \
                  | grep -iE 'userparameter_ssh|cannot load user param|invalid user param')"
    if [ -n "$LOG_ERRORS" ]; then
        fail "Agent log contains UserParameter errors after restart:" \
             "W logu agenta po restarcie są błędy dotyczące UserParameter:"
        echo "$LOG_ERRORS"
    else
        ok "No UserParameter errors in the agent log after restart" \
           "Brak błędów UserParameter w logu agenta po restarcie"
    fi
fi

# -----------------------------------------------------------------------------
step "Summary" "Podsumowanie"
# -----------------------------------------------------------------------------

if [ "$CHECK_ONLY" -eq 1 ]; then
    MODE_EN="check only (--check)"; MODE_PL="tylko sprawdzenie (--check)"
else
    MODE_EN="prepare";              MODE_PL="przygotowanie"
fi

echo "Host / Host:                      $(hostname)"
echo "Date / Data:                      $(date '+%Y-%m-%d %H:%M:%S')"
echo "State before / Stan przed:        $STATE"
echo "Mode / Tryb:                      $MODE_EN / $MODE_PL"
echo "Changes / Zmian:                  $CHANGES"
echo "Errors / Błędów:                  $ERRORS"
if [ -n "$BACKUP_FILE" ] && [ "$CHECK_ONLY" -eq 0 ]; then
    echo "UserParameter backup / Kopia:     $BACKUP_FILE"
fi

if [ "$ERRORS" -gt 0 ]; then
    echo
    echo "There are errors - do NOT switch the host to the new template until they are fixed."
    echo "Są błędy - NIE przełączaj hosta na nowy szablon, dopóki ich nie usuniesz."
    exit 1
fi

if [ "$CHECK_ONLY" -eq 0 ]; then
    echo
    echo "Host is ready. Next step in Zabbix:"
    echo "Host gotowy. Następny krok w Zabbixie:"
    echo "  Host -> Templates -> Link new templates -> 'OpenSSH Debian by Zabbix agent 2 active' -> Update"
    echo "  EN: if the host has an older SSH template with the same item keys, use Unlink and clear on it first."
    echo "  PL: jeśli host ma starszy szablon SSH z tymi samymi kluczami, najpierw użyj na nim Unlink and clear."
    if [ "$STATE" = "old" ]; then
        echo
        echo "Until the switch, old template items with removed keys will be unsupported (known issue 8)."
        echo "Do czasu przełączenia itemy starego szablonu z usuniętymi kluczami będą unsupported (znany problem 8)."
    fi
    if [ -n "$BACKUP_FILE" ]; then
        echo
        echo "Host rollback:"
        echo "Rollback hosta:"
        echo "  sudo cp -p $BACKUP_FILE $UP_FILE"
        echo "  sudo rm $SUDOERS_FILE"
        echo "  sudo systemctl restart zabbix-agent2"
    fi
fi
exit 0
