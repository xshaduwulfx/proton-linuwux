#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LINUWUX_DIR="$ROOT_DIR/scripts/linuwux"

LEGACY_REFLEX="${LINUWUX_LEGACY_REFLEX:-0}"

if [[ "$LEGACY_REFLEX" == "1" ]]
then
    HOOKS_FILE="$LINUWUX_DIR/linuwux_hooks_legacy.c"
    echo "Legacy Reflex: abilitato"
else
    HOOKS_FILE="$LINUWUX_DIR/linuwux_hooks.c"
    echo "Legacy Reflex: disabilitato"
fi

if [[ ! -f "$HOOKS_FILE" ]]
then
    echo "Errore: file hooks non trovato:"
    echo "$HOOKS_FILE"
    exit 1
fi

SOURCE_DIR="${1:-}"

if [[ -z "$SOURCE_DIR" ]]
then
    echo "Errore: directory sorgente non specificata."
    exit 1
fi

if [[ ! -d "$SOURCE_DIR" ]]
then
    echo "Errore: directory sorgente non trovata:"
    echo "$SOURCE_DIR"
    exit 1
fi

echo "== Applicazione LinUwUx experimental =="
echo "Sorgenti: $SOURCE_DIR"

WINE_UNIX_DIR="$SOURCE_DIR/wine/dlls/ntdll/unix"
HOOKS_TARGET="$WINE_UNIX_DIR/linuwux_hooks.c"

if [[ ! -d "$WINE_UNIX_DIR" ]]
then
    echo "Errore: directory Wine ntdll/unix non trovata:"
    echo "$WINE_UNIX_DIR"
    exit 1
fi

cp "$HOOKS_FILE" "$HOOKS_TARGET"

echo "Hooks copiati:"
echo "$HOOKS_TARGET"


insert_hooks_include() {
    local target="$WINE_UNIX_DIR/signal_x86_64.c"

    if [[ ! -f "$target" ]]
    then
        echo "Errore: signal_x86_64.c non trovato:"
        echo "$target"
        exit 1
    fi

    if grep -qF '#include "linuwux_hooks.c"' "$target"
    then
        echo "Include LinUwUx già presente."
        return
    fi

    local test_line
    local func_line

    test_line="$(
        grep -n '0xffff' "$target" |
        head -1 |
        cut -d: -f1
    )"

    if [[ -z "$test_line" ]]
    then
        echo "Errore: test seccomp 0xffff non trovato in:"
        echo "$target"
        exit 1
    fi

    func_line="$(
        awk -v end="$test_line" '
            NR <= end && /^static void sigsys_handler/ { line = NR }
            END { if (line) print line }
        ' "$target"
    )"

    if [[ -z "$func_line" ]]
    then
        echo "Errore: sigsys_handler Linux non trovato in:"
        echo "$target"
        exit 1
    fi

    {
        head -n "$((func_line - 1))" "$target"
        echo '#include "linuwux_hooks.c"'
        echo
        tail -n "+$func_line" "$target"
    } > "$target.tmp"

    mv "$target.tmp" "$target"

    echo "Include LinUwUx inserito in signal_x86_64.c."
}

insert_hooks_include


insert_cpuid_callsite() {
    local target="$WINE_UNIX_DIR/signal_x86_64.c"

    if grep -qF 'linuwux-cpuid-handler-call' "$target"
    then
        echo "Call-site CPUID LinUwUx già presente."
        return
    fi

    local anchor_line

    anchor_line="$(
        grep -n 'void \*steamclient_addr = NULL;' "$target" |
        head -1 |
        cut -d: -f1
    )"

    if [[ -z "$anchor_line" ]]
    then
        echo "Errore: anchor steamclient_addr non trovato in:"
        echo "$target"
        exit 1
    fi

    {
        head -n "$anchor_line" "$target"
        echo '    /* linuwux-cpuid-handler-call */'
        echo '    if (linuwux_cpuid_spoof(siginfo, sigcontext, ucontext))'
        echo '        return;'
        tail -n "+$((anchor_line + 1))" "$target"
    } > "$target.tmp"

    mv "$target.tmp" "$target"

    echo "Call-site CPUID LinUwUx inserito."
}

insert_cpuid_callsite


insert_signal_init_hooks() {
    local target="$WINE_UNIX_DIR/signal_x86_64.c"

    if grep -qF 'detect_cpu_vendor();' "$target"
    then
        echo "Hook signal_init_process già presente."
        return
    fi

    local func_line
    local anchor_line

    func_line="$(
        grep -n 'signal_init_process' "$target" |
        head -1 |
        cut -d: -f1
    )"

    if [[ -z "$func_line" ]]
    then
        echo "Errore: signal_init_process non trovato in:"
        echo "$target"
        exit 1
    fi

    anchor_line="$(
        awk -v start="$func_line" '
            NR >= start && /sigaction\( SIGSEGV, &sig_act, NULL \)/ {
                print NR
                exit
            }
        ' "$target"
    )"

    if [[ -z "$anchor_line" ]]
    then
        echo "Errore: anchor SIGSEGV non trovato in signal_init_process."
        exit 1
    fi

    {
        head -n "$anchor_line" "$target"
        echo '    detect_cpu_vendor();'
        echo '    syscall(SYS_arch_prctl, ARCH_SET_CPUID, 0);'
        tail -n "+$((anchor_line + 1))" "$target"
    } > "$target.tmp"

    mv "$target.tmp" "$target"

    echo "Hook signal_init_process inserito."
}

insert_signal_init_hooks


insert_sigsys_callsite() {
    local target="$WINE_UNIX_DIR/signal_x86_64.c"

    if grep -qF 'linuwux-sigsys-handler-call' "$target"
    then
        echo "Call-site SIGSYS LinUwUx già presente."
        return
    fi

    local test_line
    local func_line
    local anchor_line

    test_line="$(
        grep -n '0xffff' "$target" |
        head -1 |
        cut -d: -f1
    )"

    if [[ -z "$test_line" ]]
    then
        echo "Errore: test seccomp 0xffff non trovato in:"
        echo "$target"
        exit 1
    fi

    func_line="$(
        awk -v end="$test_line" '
            NR <= end && /^static void sigsys_handler/ { line = NR }
            END { if (line) print line }
        ' "$target"
    )"

    if [[ -z "$func_line" ]]
    then
        echo "Errore: sigsys_handler Linux non trovato in:"
        echo "$target"
        exit 1
    fi

    anchor_line="$(
        awk -v start="$func_line" -v end="$test_line" '
            NR >= start && NR <= end &&
            /struct[[:space:]]+syscall_frame[[:space:]]*\*[[:space:]]*frame[[:space:]]*=[[:space:]]*get_syscall_frame/ {
                print NR
                exit
            }
        ' "$target"
    )"

    if [[ -z "$anchor_line" ]]
    then
        echo "Errore: get_syscall_frame() non trovato nel sigsys_handler Linux."
        exit 1
    fi

    {
        head -n "$anchor_line" "$target"
        echo '    /* linuwux-sigsys-handler-call */'
        echo '    if (linuwux_sigsys_route(sigcontext))'
        echo '        return;'
        tail -n "+$((anchor_line + 1))" "$target"
    } > "$target.tmp"

    mv "$target.tmp" "$target"

    echo "Call-site SIGSYS LinUwUx inserito."
}

insert_sigsys_callsite


apply_hwprofile_guid() {
    local target="$SOURCE_DIR/wine/loader/wine.inf.in"
    local content_file="$LINUWUX_DIR/hwprofile_guid.reg"
    local tmp

    if [[ ! -f "$target" ]]
    then
        echo "Errore: wine.inf.in non trovato:"
        echo "$target"
        exit 1
    fi

    if [[ ! -f "$content_file" ]]
    then
        echo "Errore: hwprofile_guid.reg non trovato:"
        echo "$content_file"
        exit 1
    fi

    if grep -q 'HwProfileGuid' "$target"
    then
        echo "HwProfileGuid già presente."
        return
    fi

    tmp="$(mktemp -p "$(dirname "$target")" wine-inf.XXXXXX)"

    {
        cat "$target"
        echo
        cat "$content_file"
        echo
    } > "$tmp"

    mv "$tmp" "$target"

    echo "HwProfileGuid aggiunto a wine.inf.in."
}

apply_hwprofile_guid


apply_faketime_protocol() {
    local target="$SOURCE_DIR/wine/server/protocol.def"
    local content_file="$LINUWUX_DIR/set_faketime.protocol"
    local tmp

    if [[ ! -f "$target" ]]
    then
        echo "Errore: protocol.def non trovato:"
        echo "$target"
        exit 1
    fi

    if [[ ! -f "$content_file" ]]
    then
        echo "Errore: set_faketime.protocol non trovato:"
        echo "$content_file"
        exit 1
    fi

    if grep -qF '@REQ(set_faketime)' "$target"
    then
        echo "Protocollo set_faketime già presente."
        return
    fi

    tmp="$(mktemp -p "$(dirname "$target")" protocol-def.XXXXXX)"

    {
        cat "$target"
        echo
        cat "$content_file"
        echo
    } > "$tmp"

    mv "$tmp" "$target"

    echo "Protocollo set_faketime aggiunto."
}

apply_faketime_protocol

apply_faketime_server_patch() {
    local wine_dir="$SOURCE_DIR/wine"
    local target="$wine_dir/server/fd.c"
    local patch_file="$LINUWUX_DIR/0001-apply_faketime.patch"

    if [[ ! -f "$target" ]]
    then
        echo "Errore: server/fd.c non trovato:"
        echo "$target"
        exit 1
    fi

    if [[ ! -f "$patch_file" ]]
    then
        echo "Errore: patch faketime non trovata:"
        echo "$patch_file"
        exit 1
    fi

    if grep -qF 'DECL_HANDLER(set_faketime)' "$target"
    then
        echo "Patch server faketime già presente."
        return
    fi

    echo "Verifica preliminare patch server faketime..."

    if ! (
        cd "$wine_dir"
        patch --dry-run -Np1 --forward --fuzz=0 < "$patch_file"
    )
    then
        echo "Errore: la patch server faketime non è compatibile con questa versione di Wine."
        exit 1
    fi

    (
        cd "$wine_dir"
        patch -Np1 --forward --fuzz=0 < "$patch_file"
    )

    if ! grep -qF 'DECL_HANDLER(set_faketime)' "$target"
    then
        echo "Errore: la patch faketime sembra essere stata applicata, ma il relativo handler non è presente."
        exit 1
    fi

    echo "Patch server faketime applicata correttamente."
}

apply_faketime_server_patch

install_user_settings() {
    local source_file="$LINUWUX_DIR/user_settings.py"
    local target_file="$SOURCE_DIR/user_settings.py"
    local makefile="$SOURCE_DIR/Makefile.in"

    if [[ ! -f "$source_file" ]]
    then
        echo "Errore: user_settings.py non trovato:"
        echo "$source_file"
        exit 1
    fi

    if [[ ! -f "$makefile" ]]
    then
        echo "Errore: Makefile.in non trovato:"
        echo "$makefile"
        exit 1
    fi

    cp "$source_file" "$target_file"

    echo "user_settings.py copiato nella root dei sorgenti."

    if grep -qF 'USER_SETTINGS_REAL_TARGET' "$makefile"
    then
        echo "Regole user_settings.py già presenti in Makefile.in."
        return
    fi

    local anchor_dst
    local anchor_src
    local anchor_dist

    anchor_dst='USER_SETTINGS_PY_TARGET := $(addprefix $(DST_BASE)/,user_settings.sample.py)'
    anchor_src='$(USER_SETTINGS_PY_TARGET): $(addprefix $(SRCDIR)/,user_settings.sample.py)'
    anchor_dist='DIST_COPY_TARGETS := $(FILELOCK_TARGET) $(PROTON_PY_TARGET) \'

    if ! grep -qF "$anchor_dst" "$makefile"
    then
        echo "Errore: anchor USER_SETTINGS_PY_TARGET non trovato in Makefile.in."
        exit 1
    fi

    if ! grep -qF "$anchor_src" "$makefile"
    then
        echo "Errore: anchor USER_SETTINGS_PY_TARGET source non trovato in Makefile.in."
        exit 1
    fi

    if ! grep -qF "$anchor_dist" "$makefile"
    then
        echo "Errore: anchor DIST_COPY_TARGETS non trovato in Makefile.in."
        exit 1
    fi

    local tmp
    tmp="$(mktemp -p "$(dirname "$makefile")" makefile-in.XXXXXX)"

    awk '
        {
            print
            if ($0 == "USER_SETTINGS_PY_TARGET := $(addprefix $(DST_BASE)/,user_settings.sample.py)")
                print "USER_SETTINGS_REAL_TARGET := $(addprefix $(DST_BASE)/,user_settings.py)"
            else if ($0 == "$(USER_SETTINGS_PY_TARGET): $(addprefix $(SRCDIR)/,user_settings.sample.py)")
                print "$(USER_SETTINGS_REAL_TARGET): $(addprefix $(SRCDIR)/,user_settings.py)"
        }
    ' "$makefile" > "$tmp"

    mv "$tmp" "$makefile"

    tmp="$(mktemp -p "$(dirname "$makefile")" makefile-in.XXXXXX)"

    sed \
        's|DIST_COPY_TARGETS := $(FILELOCK_TARGET) $(PROTON_PY_TARGET) \\|DIST_COPY_TARGETS := $(FILELOCK_TARGET) $(PROTON_PY_TARGET) $(USER_SETTINGS_REAL_TARGET) \\|' \
        "$makefile" > "$tmp"

    mv "$tmp" "$makefile"

    if ! grep -qF 'USER_SETTINGS_REAL_TARGET := $(addprefix $(DST_BASE)/,user_settings.py)' "$makefile"
    then
        echo "Errore: regola USER_SETTINGS_REAL_TARGET non inserita."
        exit 1
    fi

    if ! grep -qF '$(USER_SETTINGS_REAL_TARGET): $(addprefix $(SRCDIR)/,user_settings.py)' "$makefile"
    then
        echo "Errore: regola source user_settings.py non inserita."
        exit 1
    fi

    if ! grep -qF 'DIST_COPY_TARGETS := $(FILELOCK_TARGET) $(PROTON_PY_TARGET) $(USER_SETTINGS_REAL_TARGET)' "$makefile"
    then
        echo "Errore: DIST_COPY_TARGETS non aggiornato."
        exit 1
    fi

    echo "Makefile.in aggiornato per includere user_settings.py."
}

install_user_settings
