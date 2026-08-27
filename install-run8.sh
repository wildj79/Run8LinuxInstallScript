#!/usr/bin/env bash
#
# Run 8 V3 installer for Linux/Wine
#
# This script is intentionally idempotent:
#   - Run it once to install Run 8 and all DLC currently in the installer directory.
#   - Add new DLC installers later and run it again.
#   - Installed installers are tracked in manifest.txt.
#
# Usage:
#   ./install-run8.sh
#   ./install-run8.sh --status
#   ./install-run8.sh --dry-run
#   ./install-run8.sh --verbose
#

set -u

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
INSTALLER_DIR="$SCRIPT_DIR"

# Change this if you want Run 8 somewhere other than ~/Games/Run8.
RUN8_ROOT="${RUN8_ROOT:-$HOME/Games/Run8}"

WINEPREFIX="$RUN8_ROOT/prefix"
RUN8_DIR="$WINEPREFIX/drive_c/Run8Studios/Run8 Train Simulator V3"

MANIFEST="$RUN8_ROOT/manifest.txt"
LOG_FILE="$RUN8_ROOT/install.log"

BASE_INSTALLER="run8v3_install.exe"
UPDATER_INSTALLER="r8v3_run8updaterinstaller.exe"

RUN8_EXE="$RUN8_DIR/Run-8 Train Simulator V3.exe"
V2_SHIM="$RUN8_DIR/Run-8 Train Simulator V2.exe"

VERBOSE=0

# ---------------------------------------------------------------------------
# Output helpers
# ---------------------------------------------------------------------------

info() {
    printf '\n\033[1;34m==> %s\033[0m\n' "$*"
}

success() {
    printf '\033[1;32m[ OK ]\033[0m %s\n' "$*"
}

warning() {
    printf '\033[1;33m[WARN]\033[0m %s\n' "$*" >&2
}

error() {
    printf '\033[1;31m[FAIL]\033[0m %s\n' "$*" >&2
}

die() {
    error "$*"
    exit 1
}

# ---------------------------------------------------------------------------
# Validation / setup
# ---------------------------------------------------------------------------

check_dependencies() {
    command -v wine >/dev/null 2>&1 || die "Wine is not installed or not in PATH."
}

initialize_installation() {
    mkdir -p "$RUN8_ROOT"

    if [[ ! -f "$MANIFEST" ]]; then
        cat > "$MANIFEST" <<EOF
# Run 8 V3 installation manifest
# Installer filename<TAB>installation timestamp
EOF
    fi

    touch "$LOG_FILE"
}

# ---------------------------------------------------------------------------
# Manifest handling
# ---------------------------------------------------------------------------

manifest_contains() {
    local installer="$1"

    grep -Fq -- "$installer"$'\t' "$MANIFEST" 2>/dev/null
}

manifest_add() {
    local installer="$1"

    if ! manifest_contains "$installer"; then
        printf '%s\t%s\n' \
            "$installer" \
            "$(date --iso-8601=seconds)" >> "$MANIFEST"
    fi
}

# ---------------------------------------------------------------------------
# Wine process handling
# ---------------------------------------------------------------------------

run_windows_installer() {
    local installer="$1"
    local installer_path="$INSTALLER_DIR/$installer"

    [[ -f "$installer_path" ]] || die "Installer not found: $installer_path"

    info "Running $installer"

    printf '\n[%s] Running: %s\n' \
        "$(date --iso-8601=seconds)" \
        "$installer" >> "$LOG_FILE"

    run_external_process wine "$installer_path"

    local status=$?

    if [[ $status -ne 0 ]]; then
        error "$installer exited with status $status."
        return "$status"
    fi

    success "$installer completed."
    return 0
}

run_external_process() {
    if [[ "$VERBOSE" -eq 1 ]]; then
        WINEPREFIX="$WINEPREFIX" "$@" 2>&1 | tee -a "$LOG_FILE"
        return "${PIPESTATUS[0]}"
    fi

    WINEPREFIX="$WINEPREFIX" "$@" >/dev/null 2>&1
}

confirm_installer_success() {
    local installer="$1"
    local response

    while true; do
        printf '\n'
        printf '%s\n' '──────────────────────────────────────────────'
        printf 'Did the installer complete successfully?'
        printf '\n\n'
        printf '  %s\n' "$installer"
        printf '%s\n' '──────────────────────────────────────────────'
        printf '[y] Yes, installation completed successfully'
        printf '\n'
        printf '[n] No, installation did not complete'
        printf '\n'
        printf '[r] Run the installer again'
        printf '\n\n'

        read -r -p 'Choice [y/n/r]: ' response </dev/tty

        case "${response,,}" in
            y|yes)
                return 0
                ;;
            n|no)
                return 1
                ;;
            r|retry)
                return 2
                ;;
            *)
                printf 'Please enter y, n, or r.\n'
                ;;
        esac
    done
}

# Run an installer exactly once and record it only after successful completion.
run_once() {
    local installer="$1"
    local result

    if manifest_contains "$installer"; then
        printf '\033[2m[ SKIP ]\033[0m %s\n' "$installer"
        return 0
    fi

    while true; do
        if ! run_windows_installer "$installer"; then
            error "$installer returned a non-zero exit code."
            return 1
        fi

        confirm_installer_success "$installer"
        result=$?

        case "$result" in
            0)
                manifest_add "$installer"
                success "Recorded $installer in manifest."
                return 0
                ;;

            1)
                error "$installer was not completed successfully."
                return 1
                ;;

            2)
                info "Retrying $installer..."
                ;;
        esac
    done
}

# Run an installer regardless of whether it appears in the manifest.
run_required() {
    local installer="$1"

    if ! run_windows_installer "$installer"; then
        die "Required installer failed: $installer"
    fi
}

# ---------------------------------------------------------------------------
# Run 8 installation phases
# ---------------------------------------------------------------------------

install_base() {
    if manifest_contains "$BASE_INSTALLER"; then
        success "Run 8 V3 base installation already completed."
        return
    fi

    info "Installing Run 8 V3"

    run_once "$BASE_INSTALLER" || die "Base Run 8 installation failed."

    [[ -f "$RUN8_EXE" ]] || \
        warning "Run 8 executable was not found at the expected path:
  $RUN8_EXE

The installer may have used a different installation path."
}

create_v2_compatibility_shim() {
    info "Creating V2 compatibility shim"

    mkdir -p "$RUN8_DIR"

    if [[ -e "$V2_SHIM" ]]; then
        success "V2 compatibility file already exists."
        return
    fi

    # Older V2 DLC installers only need this filename to exist.
    # An empty file is intentional; it is not a real V2 executable.
    touch "$V2_SHIM"

    success "Created:"
    printf '  %s\n' "$V2_SHIM"
}

install_updater() {
    info "Installing Run 8 updater"

    run_once "$UPDATER_INSTALLER" || \
        die "Run 8 updater installation failed."
}

find_dlc_installers() {
    local file
    local name

    shopt -s nullglob

    for file in "$INSTALLER_DIR"/*.exe; do
        name="$(basename -- "$file")"

        case "$name" in
            "$BASE_INSTALLER"|"$UPDATER_INSTALLER")
                continue
                ;;
            *)
                printf '%s\n' "$name"
                ;;
        esac
    done

    shopt -u nullglob
}

install_dlc() {
    local dlc
    local found=0
    local installed_new=0

    info "Scanning for DLC installers"

    while IFS= read -r dlc; do
        [[ -n "$dlc" ]] || continue
        found=1

        if manifest_contains "$dlc"; then
            printf '\033[2m[ SKIP ]\033[0m %s\n' "$dlc"
            continue
        fi

        printf '\nInstalling DLC: %s\n' "$dlc"

        if run_once "$dlc"; then
            installed_new=1
        else
            die "DLC installation failed: $dlc"
        fi
    done < <(find_dlc_installers)

    if [[ $found -eq 0 ]]; then
        warning "No DLC installers were found in:"
        printf '  %s\n' "$INSTALLER_DIR"
    fi

    DLC_INSTALLED_NEW=$installed_new
}

finalize_installation() {
    # If new DLC was installed, rerun the V3 installer so V2-era DLC can
    # be migrated/registered with the V3 installation.
    if [[ "${DLC_INSTALLED_NEW:-0}" -eq 1 ]]; then
        info "Rerunning Run 8 V3 installer for DLC migration"

        run_required "$BASE_INSTALLER"

        info "Running Run 8 updater after DLC installation"

        run_updater
    else
        success "No new DLC was installed; migration/update not required."
    fi
}

# ---------------------------------------------------------------------------
# Updater
# ---------------------------------------------------------------------------
run_updater() {
    local updater_exe="$RUN8_DIR/Run8_Updater.exe"

    if [[ ! -f "$updater_exe" ]]; then
        die "Run 8 updater was not found at:
    $updater_exe"
    fi

    info "Running Run 8 updater"

    printf '\n[%s] Running Run8_Updater.exe\n' \
        "$(date --iso-8601=seconds)" >> "$LOG_FILE"

    run_external_process wine "$updater_exe"

    local status=$?

    if [[ $status -ne 0 ]]; then
        die "Run 8 updater failed with status $status."
    fi

    success "Run 8 updater completed."
}

# ---------------------------------------------------------------------------
# Status / dry run
# ---------------------------------------------------------------------------

show_status() {
    initialize_installation

    printf '\n'
    printf 'Run 8 V3 installation\n'
    printf '%s\n' '====================='
    printf 'Install root: %s\n' "$RUN8_ROOT"
    printf 'Wine prefix:  %s\n' "$WINEPREFIX"
    printf 'Game directory: %s\n' "$RUN8_DIR"
    printf 'Manifest: %s\n\n' "$MANIFEST"

    if manifest_contains "$BASE_INSTALLER"; then
        printf 'Base installation: \033[1;32mINSTALLED\033[0m\n'
    else
        printf 'Base installation: \033[1;33mNOT INSTALLED\033[0m\n'
    fi

    if manifest_contains "$UPDATER_INSTALLER"; then
        printf 'Updater installer:  \033[1;32mINSTALLED\033[0m\n'
    else
        printf 'Updater installer:  \033[1;33mNOT INSTALLED\033[0m\n'
    fi

    printf '\nDLC installers:\n'

    local dlc
    local found=0

    while IFS= read -r dlc; do
        [[ -n "$dlc" ]] || continue
        found=1

        if manifest_contains "$dlc"; then
            printf '  \033[1;32m[INSTALLED]\033[0m %s\n' "$dlc"
        else
            printf '  \033[1;33m[NEW]\033[0m       %s\n' "$dlc"
        fi
    done < <(find_dlc_installers)

    [[ $found -eq 1 ]] || printf '  (none found)\n'

    printf '\nV2 compatibility file: '
    [[ -e "$V2_SHIM" ]] && printf '\033[1;32mPRESENT\033[0m\n' || printf '\033[1;33mMISSING\033[0m\n'

    printf 'V3 executable:         '
    [[ -f "$RUN8_EXE" ]] && printf '\033[1;32mPRESENT\033[0m\n' || printf '\033[1;33mMISSING\033[0m\n'
}

show_dry_run() {
    initialize_installation

    printf '\n'
    printf 'Run 8 V3 dry run\n'
    printf '%s\n' '================'
    printf 'Installer directory: %s\n\n' "$INSTALLER_DIR"

    if ! manifest_contains "$BASE_INSTALLER"; then
        printf 'Would install: %s\n' "$BASE_INSTALLER"
    else
        printf 'Would skip:    %s\n' "$BASE_INSTALLER"
    fi

    if ! manifest_contains "$UPDATER_INSTALLER"; then
        printf 'Would install: %s\n' "$UPDATER_INSTALLER"
    else
        printf 'Would skip:    %s\n' "$UPDATER_INSTALLER"
    fi

    printf '\nDLC:\n'

    local dlc
    local found=0
    local new_dlc=0

    while IFS= read -r dlc; do
        [[ -n "$dlc" ]] || continue
        found=1

        if manifest_contains "$dlc"; then
            printf '  Would skip:    %s\n' "$dlc"
        else
            printf '  Would install: %s\n' "$dlc"
            new_dlc=1
        fi
    done < <(find_dlc_installers)

    [[ $found -eq 1 ]] || printf '  (none found)\n'

    if [[ $new_dlc -eq 1 ]]; then
        printf '\nAfter new DLC:\n'
        printf '  Would rerun: %s\n' "$BASE_INSTALLER"
        printf '  Would run the Run 8 updater.\n'
    fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

COMMAND=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --verbose|-v)
            VERBOSE=1
            ;;
        --status|--dry-run|--update|--help|-h)
            [[ -z "$COMMAND" ]] || die "Only one command option may be used."
            COMMAND="$1"
            ;;
        *)
            die "Unknown option: $1 (try --help)"
            ;;
    esac

    shift
done

case "$COMMAND" in
    --status)
        check_dependencies
        show_status
        exit 0
        ;;
    --dry-run)
        check_dependencies
        show_dry_run
        exit 0
        ;;
    --update)
        check_dependencies
        initialize_installation
        run_updater
        exit 0
        ;;
    --help|-h)
        cat <<EOF
Run 8 V3 Wine installer

Usage:
  $0 [--verbose]  Install Run 8 and any uninstalled DLC
  $0 --status     Show installation/manifest status
  $0 --dry-run    Show what would be installed
  $0 --update     Run the Run8 updater
  $0 --help       Show this help

Options:
    --verbose, -v   Show Wine output and append it to the install log

Environment:
  RUN8_ROOT       Installation root (default: \$HOME/Games/Run8)

Installer directory:
  $INSTALLER_DIR
EOF
        exit 0
        ;;
    "")
        ;;
esac

check_dependencies
initialize_installation

info "Run 8 V3 installation"
printf 'Installer directory: %s\n' "$INSTALLER_DIR"
printf 'Installation root:   %s\n' "$RUN8_ROOT"
printf 'Wine prefix:         %s\n' "$WINEPREFIX"
printf 'Game directory:      %s\n' "$RUN8_DIR"

mkdir -p "$WINEPREFIX"

# Establish the Wine prefix before doing anything else.
if [[ ! -d "$WINEPREFIX/drive_c" ]]; then
    info "Creating Wine prefix"
    run_external_process wineboot -u
    status=$?
    [[ $status -eq 0 ]] || die "Failed to initialize Wine prefix."
fi

install_base
create_v2_compatibility_shim
install_updater
install_dlc
finalize_installation

info "Run 8 installation process complete"

printf '\nRun 8 executable:\n  %s\n' "$RUN8_EXE"
printf '\nManifest:\n  %s\n' "$MANIFEST"
printf '\nLog:\n  %s\n' "$LOG_FILE"
