#!/usr/bin/env bash
# =============================================================================
# OnePlus Debloater Script -- v2.0 (OxygenOS 16 / OnePlus 15 ready)
# =============================================================================
# Fork:     github.com/radnou/OnePlus-Debloater-Script
# Original: github.com/ronellsalunke/OnePlus-Debloater-Script
#
# Compatible: bash 3.2+ (macOS stock) AND bash 4+/5+
# Pas de root requis. Detection auto OnePlus 15 / OxygenOS 16.
# =============================================================================

set -eu

# ---------- COULEURS ----------
if [ -t 1 ]; then
  C_RST='\033[0m'; C_RED='\033[31m'; C_GRN='\033[32m'; C_YLW='\033[33m'
  C_BLU='\033[34m'; C_CYN='\033[36m'; C_BLD='\033[1m'
else
  C_RST=''; C_RED=''; C_GRN=''; C_YLW=''; C_BLU=''; C_CYN=''; C_BLD=''
fi
say()  { printf '%b\n' "$*"; }
ok()   { printf '%b\n' "${C_GRN}OK${C_RST} $*"; }
warn() { printf '%b\n' "${C_YLW}!${C_RST}  $*"; }
err()  { printf '%b\n' "${C_RED}X${C_RST}  $*" >&2; }
hdr()  { printf '\n%b\n' "${C_BLD}${C_CYN}== $* ==${C_RST}"; }

# ---------- USAGE ----------
usage() {
  cat <<EOF

  OnePlus Debloater Script v2.0

  USAGE:
    ./debloat.sh [OPTIONS] [CATEGORY...]

  OPTIONS:
    --disable      Desactive les packages (reversible, RECOMMANDE, defaut)
    --uninstall    Desinstalle (--user 0, restaurable via factory reset)
    --restore      Reactive/reinstalle les packages
    --dry-run      Affiche ce qui serait fait sans rien faire
    --yes, -y      Skip toutes les confirmations
    --serial XYZ   Cible un device ADB specifique (sinon le seul)
    --log FILE     Chemin du fichier log (defaut: ./debloat-TS.log)
    --list         Liste toutes les categories disponibles
    -h, --help     Affiche cette aide

  CATEGORIES (si omises, toutes les SAFE sont proposees):
    meta           Packages Facebook/Meta (3-5)
    google-legacy  Google Duo (Tachyon), Talkback, Android Auto, Print (4)
    oplus-pub      Pub OPlus : Atlas, ContentPortal, PsCanvas (3)
    coloros        ColorOS legacy : Weather, Compass, ChildrenSpace... (8)
    heytap         HeyTap : Accessory, Pictorial, Browser (3)
    oneplus-extra  OnePlus optionnels : Note, BrickMode, Store, IR (6-8)
    google-health  Health Connect (si pas utilise) (2)
    all-safe       Toutes les categories ci-dessus (env. 28-32 packages)

  DEVICES SUPPORTES:
    OnePlus 15 (CPH2747 / OP611FL1) -- OxygenOS 16+
    OnePlus 13 (CPH2649) -- OxygenOS 15+

  EXEMPLES:
    ./debloat.sh --dry-run                    # voir ce qui serait fait
    ./debloat.sh meta google-legacy           # 2 categories seulement
    ./debloat.sh --uninstall --yes all-safe   # total non-interactif
    ./debloat.sh --restore                    # tout restaurer

EOF
}

# ---------- ARGUMENTS ----------
MODE="disable"
DRY_RUN=0
YES=0
SERIAL=""
LOG_FILE=""
CATEGORIES=""
TS=$(date +%Y%m%d-%H%M%S)

while [ $# -gt 0 ]; do
  case "$1" in
    --disable)   MODE="disable" ;;
    --uninstall) MODE="uninstall" ;;
    --restore)   MODE="restore" ;;
    --dry-run)   DRY_RUN=1 ;;
    --yes|-y)    YES=1 ;;
    --serial)    SERIAL="$2"; shift ;;
    --log)       LOG_FILE="$2"; shift ;;
    --list)      MODE="list" ;;
    -h|--help)   usage; exit 0 ;;
    -*)          err "Option inconnue: $1"; usage; exit 1 ;;
    *)           CATEGORIES="$CATEGORIES $1" ;;
  esac
  shift
done

LOG_FILE="${LOG_FILE:-./debloat-${TS}.log}"
ADB_CMD="adb"
[ -n "$SERIAL" ] && ADB_CMD="adb -s $SERIAL"

# ---------- PACKAGE LISTS (bash 3 compatible, OOS 16 / OnePlus 15 validated 2026-05) ----------
ALL_CATEGORIES="meta google-legacy oplus-pub coloros heytap oneplus-extra google-health"

# Format : <category>|<label>|<packages space-separated>
PKG_meta="Meta / Facebook bloat|com.facebook.appmanager com.facebook.system com.facebook.services com.facebook.pages.app com.facebook.katana"
PKG_google_legacy="Google apps obsoletes|com.google.android.apps.tachyon com.google.android.marvin.talkback com.google.android.printservice.recommendation com.google.android.projection.gearhead"
PKG_oplus_pub="Publicite OPlus|com.oplus.atlas com.oplus.contentportal com.oplus.pscanvas"
PKG_coloros="ColorOS legacy|com.coloros.weather.service com.coloros.video com.coloros.compass2 com.coloros.childrenspace com.coloros.scenemode com.coloros.translate.engine com.coloros.smartsidebar com.coloros.systemclone"
PKG_heytap="HeyTap services|com.heytap.accessory com.heytap.pictorial com.heytap.browser"
PKG_oneplus_extra="OnePlus apps optionnels|com.oneplus.note com.oneplus.brickmode com.oneplus.store com.oplus.consumerIRApp com.oneplus.mall com.oneplus.membership com.oneplus.opwlb com.oneplus.twspods"
PKG_google_health="Google Health Connect|com.google.android.healthconnect.controller com.google.android.health.connect.backuprestore"

# Descriptions individuelles (function-based, bash 3 OK)
pkg_desc() {
  case "$1" in
    com.facebook.appmanager) echo "App installer Meta silencieux" ;;
    com.facebook.system) echo "Services Meta background" ;;
    com.facebook.services) echo "Services Meta annexes" ;;
    com.facebook.pages.app) echo "App Facebook Pages preinstallee" ;;
    com.facebook.katana) echo "Facebook app (si preinstallee)" ;;
    com.google.android.apps.tachyon) echo "Google Duo (deprecie, remplace par Meet)" ;;
    com.google.android.marvin.talkback) echo "Lecteur d'ecran (si non utilise)" ;;
    com.google.android.printservice.recommendation) echo "Print recommendations" ;;
    com.google.android.projection.gearhead) echo "Android Auto (si non utilise)" ;;
    com.oplus.atlas) echo "Carte des services Oppo (pub)" ;;
    com.oplus.contentportal) echo "Pub et recommandations" ;;
    com.oplus.pscanvas) echo "Photo Stories canvas" ;;
    com.coloros.weather.service) echo "Service meteo legacy" ;;
    com.coloros.video) echo "Lecteur video legacy" ;;
    com.coloros.compass2) echo "Boussole de base" ;;
    com.coloros.childrenspace) echo "Mode enfants" ;;
    com.coloros.scenemode) echo "Mode simplifie seniors" ;;
    com.coloros.translate.engine) echo "Traducteur legacy" ;;
    com.coloros.smartsidebar) echo "Smart Sidebar" ;;
    com.coloros.systemclone) echo "App Clone (dual apps)" ;;
    com.heytap.accessory) echo "Compagnon Oppo wearables" ;;
    com.heytap.pictorial) echo "Wallpapers carrousel lockscreen" ;;
    com.heytap.browser) echo "Browser legacy" ;;
    com.oneplus.note) echo "Notes (si vous avez Obsidian/Markor)" ;;
    com.oneplus.brickmode) echo "Zen Mode legacy" ;;
    com.oneplus.store) echo "Boutique OnePlus" ;;
    com.oplus.consumerIRApp) echo "Telecommande IR (le 15 n'a pas le blaster)" ;;
    com.oneplus.mall) echo "Boutique OnePlus (anciens devices)" ;;
    com.oneplus.membership) echo "OnePlus Membership" ;;
    com.oneplus.opwlb) echo "OnePlus WLB" ;;
    com.oneplus.twspods) echo "OnePlus TWS Pods" ;;
    com.google.android.healthconnect.controller) echo "Health Connect (si Apple Health/Strava/Withings)" ;;
    com.google.android.health.connect.backuprestore) echo "Health Connect backup" ;;
    *) echo "" ;;
  esac
}

# Normalise category name (dashes to underscore) for variable lookup
norm_cat() {
  echo "$1" | tr '-' '_'
}

cat_label() {
  local var="PKG_$(norm_cat "$1")"
  eval "echo \"\${$var}\"" | cut -d'|' -f1
}
cat_pkgs() {
  local var="PKG_$(norm_cat "$1")"
  eval "echo \"\${$var}\"" | cut -d'|' -f2
}

# ---------- HELPERS ----------
check_adb() {
  command -v adb >/dev/null 2>&1 || { err "adb introuvable. Installer Platform Tools : https://developer.android.com/studio/releases/platform-tools  -  ou : brew install --cask android-platform-tools"; exit 2; }
  local devices
  devices=$($ADB_CMD devices | grep -E "device$" | wc -l | tr -d ' ')
  if [ "$devices" -eq 0 ]; then
    err "Aucun device connecte. Verifiez cable + autorisation ADB."
    exit 3
  fi
  if [ "$devices" -gt 1 ] && [ -z "$SERIAL" ]; then
    err "Plusieurs devices detectes. Utilisez --serial <ID> :"
    $ADB_CMD devices -l
    exit 4
  fi
}

detect_device() {
  local brand model device os_ver android
  brand=$($ADB_CMD shell getprop ro.product.brand | tr -d '\r')
  model=$($ADB_CMD shell getprop ro.product.model | tr -d '\r')
  device=$($ADB_CMD shell getprop ro.product.device | tr -d '\r')
  os_ver=$($ADB_CMD shell getprop ro.build.version.oplusrom | tr -d '\r')
  android=$($ADB_CMD shell getprop ro.build.version.release | tr -d '\r')
  DETECTED_DEVICE="$brand $model ($device)"
  DETECTED_OS="OxygenOS $os_ver - Android $android"
  if [ "$brand" != "OnePlus" ] && [ "$brand" != "OPPO" ]; then
    warn "Device non-OnePlus/OPPO detecte ($brand). Continuez avec prudence."
  fi
  case "$device" in
    OP611FL1|OP9D89L1) ok "OnePlus 15 (CPH2747) detecte" ;;
    OP583DL1|OP6431L1) ok "OnePlus 13 detecte" ;;
    *) warn "Modele '$device' non explicitement teste. Continuez avec prudence." ;;
  esac
}

pkg_installed() {
  $ADB_CMD shell "pm list packages $1" 2>/dev/null | grep -q "package:${1}$"
}

pkg_state() {
  $ADB_CMD shell "pm dump $1" 2>/dev/null | grep -E "^[[:space:]]*enabled=" | head -1 | sed 's|.*enabled=||' | awk '{print $1}'
}

apply_disable() {
  pkg_installed "$1" || { echo "absent"; return; }
  [ "$DRY_RUN" = "1" ] && { echo "would-disable"; return; }
  if $ADB_CMD shell "pm disable-user --user 0 $1" >/dev/null 2>&1; then echo "disabled"; else echo "failed"; fi
}
apply_uninstall() {
  pkg_installed "$1" || { echo "absent"; return; }
  [ "$DRY_RUN" = "1" ] && { echo "would-uninstall"; return; }
  if $ADB_CMD shell "pm uninstall --user 0 $1" >/dev/null 2>&1; then echo "uninstalled"; else echo "failed"; fi
}
apply_restore() {
  local r1 r2
  r1=$($ADB_CMD shell "pm enable $1" 2>&1)
  r2=$($ADB_CMD shell "cmd package install-existing $1" 2>&1)
  if echo "$r1$r2" | grep -qE "enabled|Installed"; then echo "restored"; else echo "noop"; fi
}

list_categories() {
  hdr "Categories disponibles"
  for cat in $ALL_CATEGORIES; do
    local label pkgs count
    label=$(cat_label "$cat")
    pkgs=$(cat_pkgs "$cat")
    count=$(echo $pkgs | wc -w | tr -d ' ')
    printf "  ${C_BLD}%-15s${C_RST} ${C_BLU}%s${C_RST} (%d packages)\n" "$cat" "$label" "$count"
  done
  echo
}

process_category() {
  local cat="$1"
  local label pkgs
  label=$(cat_label "$cat")
  pkgs=$(cat_pkgs "$cat")
  local count
  count=$(echo $pkgs | wc -w | tr -d ' ')

  hdr "$label  ($count packages)"

  if [ "$YES" -eq 0 ] && [ "$MODE" != "restore" ]; then
    say "Packages :"
    for pkg in $pkgs; do
      local state="?"
      if pkg_installed "$pkg"; then
        local s; s=$(pkg_state "$pkg")
        if [ "$s" = "2" ] || [ "$s" = "3" ] || [ "$s" = "4" ]; then
          state="${C_YLW}deja desactive${C_RST}"
        else
          state="${C_GRN}installe${C_RST}"
        fi
      else
        state="${C_BLU}absent${C_RST}"
      fi
      local d
      d=$(pkg_desc "$pkg")
      printf "  %-50s %b  -- %s\n" "$pkg" "$state" "$d"
    done
    printf '\n'
    printf 'Appliquer %s sur cette categorie ? [y/N] ' "$MODE"
    read -r ans
    case "$ans" in [Yy]*) ;; *) warn "Categorie skipee"; return ;; esac
  fi

  for pkg in $pkgs; do
    local result
    case "$MODE" in
      disable)   result=$(apply_disable "$pkg") ;;
      uninstall) result=$(apply_uninstall "$pkg") ;;
      restore)   result=$(apply_restore "$pkg") ;;
    esac
    printf "  %-55s %s\n" "$pkg" "$result" | tee -a "$LOG_FILE"
  done
}

# ---------- MAIN ----------
say "${C_BLD}OnePlus Debloater v2.0 -- OxygenOS 16 / OnePlus 15 ready${C_RST}"
say "Mode: ${C_CYN}${MODE}${C_RST} - Dry-run: ${DRY_RUN} - Log: ${LOG_FILE}"

if [ "$MODE" = "list" ]; then list_categories; exit 0; fi

check_adb
detect_device
say "Device  : ${C_GRN}${DETECTED_DEVICE}${C_RST}"
say "OS      : ${C_GRN}${DETECTED_OS}${C_RST}"

# Si aucune categorie passee -> toutes
if [ -z "$CATEGORIES" ] || [ "$(echo $CATEGORIES | tr -d ' ')" = "" ]; then
  CATEGORIES="$ALL_CATEGORIES"
  warn "Aucune categorie specifiee -> toutes les SAFE seront proposees."
fi

# Resoudre 'all' / 'all-safe'
NEW_CATS=""
for c in $CATEGORIES; do
  case "$c" in
    all|all-safe) NEW_CATS="$ALL_CATEGORIES"; break ;;
    *) NEW_CATS="$NEW_CATS $c" ;;
  esac
done
CATEGORIES="$NEW_CATS"

mkdir -p "$(dirname "$LOG_FILE")"
echo "[$(date)] start mode=$MODE dry-run=$DRY_RUN device=$DETECTED_DEVICE os=$DETECTED_OS" >> "$LOG_FILE"

for cat in $CATEGORIES; do
  process_category "$cat"
done

hdr "Termine"
say "Log : ${C_BLU}${LOG_FILE}${C_RST}"
case "$MODE" in
  disable)   say "${C_GRN}Reversibilite : 100%${C_RST}  ./debloat.sh --restore" ;;
  uninstall) say "${C_YLW}Restauration via factory reset${C_RST} ou : adb shell cmd package install-existing <pkg>" ;;
  restore)   say "${C_GRN}Restauration appliquee${C_RST}" ;;
esac
