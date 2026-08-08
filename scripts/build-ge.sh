#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

WORKDIR="/mnt/hdd2tb/proton-linuwux-work"
OUTPUT="$ROOT_DIR/output"

mkdir -p "$WORKDIR"
mkdir -p "$OUTPUT"

echo "== Rilevamento ultima release Proton-GE =="

GE_TAG="$(
    curl -fsSL \
        https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/latest |
    python3 -c 'import json, sys; print(json.load(sys.stdin)["tag_name"])'
)"

if [[ -z "$GE_TAG" ]]
then
    echo "Errore: impossibile rilevare l'ultima release Proton-GE."
    exit 1
fi

echo "Ultima release rilevata: $GE_TAG"

echo "== Clonazione Proton-GE $GE_TAG =="

cd "$WORKDIR"

rm -rf proton-ge-custom

git clone \
    --branch "$GE_TAG" \
    --single-branch \
    https://github.com/GloriousEggroll/proton-ge-custom.git \
    proton-ge-custom

cd proton-ge-custom


echo "== Aggiornamento submodule =="

git submodule sync --recursive

for attempt in 1 2 3 4 5
do
    echo "Tentativo submodule $attempt di 5"

    if git submodule update --init --recursive --jobs 1
    then
        break
    fi

    if [ "$attempt" -eq 5 ]
    then
        echo "Errore: impossibile scaricare tutti i submodule dopo 5 tentativi."
        exit 1
    fi

    wait_seconds=$((attempt * 60))

    echo "Download fallito. Attendo $wait_seconds secondi prima di riprovare..."
    sleep "$wait_seconds"
done

echo "== Preparazione Proton =="

./patches/protonprep-valve-staging.sh

echo "== Applicazione LinUwUx experimental =="

EXPERIMENTAL_SCRIPT="$ROOT_DIR/scripts/linuwux/apply-experimental.sh"

if [[ ! -f "$EXPERIMENTAL_SCRIPT" ]]
then
    echo "Errore: apply-experimental.sh non trovato:"
    echo "$EXPERIMENTAL_SCRIPT"
    exit 1
fi

bash "$EXPERIMENTAL_SCRIPT" "$WORKDIR/proton-ge-custom"

echo "LinUwUx experimental applicato correttamente."

echo "== Configurazione build =="

mkdir -p build

cd build


../configure.sh \
    --build-name="${GE_TAG}-LinUwUx"


echo "== Download preventivo xrandr =="

XRANDR_VERSION="1.5.4"
XRANDR_FILENAME="xrandr-${XRANDR_VERSION}.tar.xz"
XRANDR_DIR="$WORKDIR/proton-ge-custom/contrib"
XRANDR_TARBALL="$XRANDR_DIR/$XRANDR_FILENAME"
XRANDR_URL="https://xorg.freedesktop.org/archive/individual/app/$XRANDR_FILENAME"
XRANDR_SHA256="2cafccb2aaf2491a4068676117a0d4f90ab307724b96fffc54cd1da953779400"

mkdir -p "$XRANDR_DIR"
rm -f "$XRANDR_TARBALL"

wget \
    --https-only \
    --tries=5 \
    --timeout=30 \
    -O "$XRANDR_TARBALL" \
    "$XRANDR_URL"

echo "$XRANDR_SHA256  $XRANDR_TARBALL" | sha256sum --check -

echo "== Compilazione =="

make V=1 VERBOSE=1 redist 2>&1 | tee "$ROOT_DIR/build-ge.log"

echo "== Copia risultato =="

find . -maxdepth 1 -name "*.tar.*" -exec cp {} "$OUTPUT/" \;

echo "== Proton-GE completato =="

ls -lh "$OUTPUT"
