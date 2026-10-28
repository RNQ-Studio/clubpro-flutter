#!/usr/bin/env bash
# Build apps/main untuk web (ENV=prod) lalu deploy ke Firebase Hosting
# https://ceo-pro.web.app (site `ceo-pro`, project `clubpro-ceo`, lihat firebase.json).
#
#   GOOGLE_SERVER_CLIENT_ID=xxxx.apps.googleusercontent.com tool/deploy_web.sh
#   tool/deploy_web.sh --channel uji     # preview channel, live tidak tersentuh
#   tool/deploy_web.sh --build-only      # hanya build ke apps/main/build/web
#
# GOOGLE_SERVER_CLIENT_ID = Web client ID OAuth yang sama dengan APK
# (CLUBPRO_GOOGLE_SERVER_CLIENT_ID di .clubpro-release/env.*). Di web ia dipakai
# sebagai `clientId` tombol Google; https://ceo-pro.web.app harus terdaftar di
# "Authorized JavaScript origins" client tersebut. Kosong → tombol login
# menampilkan "belum dikonfigurasi".
#
# Project Firebase: --project <id>, atau FIREBASE_PROJECT, atau default di
# .firebaserc (`clubpro-ceo`).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CHANNEL=""
BUILD_ONLY=0
PROJECT="${FIREBASE_PROJECT:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --channel) CHANNEL="$2"; shift 2 ;;
    --project) PROJECT="$2"; shift 2 ;;
    --build-only) BUILD_ONLY=1; shift ;;
    *) echo "Argumen tidak dikenal: $1" >&2; exit 2 ;;
  esac
done

if [[ -z "${GOOGLE_SERVER_CLIENT_ID:-}" ]]; then
  echo "⚠️  GOOGLE_SERVER_CLIENT_ID kosong → \"Masuk dengan Google\" di web belum aktif." >&2
fi

# Nomor build = jumlah commit HEAD: naik terus di main tanpa commit bump, tampil di
# app sebagai "Versi x.y.z+N".
SHA="$(git -C "$ROOT" rev-parse HEAD)"
BUILD_NUMBER="$(git -C "$ROOT" rev-list --count HEAD)"
DIRTY=false
[[ -n "$(git -C "$ROOT" status --porcelain)" ]] && DIRTY=true

cd "$ROOT/apps/main"
flutter build web --release \
  --build-number="$BUILD_NUMBER" \
  --dart-define=ENV=prod \
  --dart-define=GOOGLE_SERVER_CLIENT_ID="${GOOGLE_SERVER_CLIENT_ID:-}"

# Stempel rilis: <site>/release.json menunjukkan commit yang sedang live.
cat > build/web/release.json <<EOF
{"sha": "$SHA", "build_number": $BUILD_NUMBER, "dirty": $DIRTY, "built_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"}
EOF

[[ $BUILD_ONLY == 1 ]] && exit 0

cd "$ROOT"
PROJECT_ARGS=()
[[ -n "$PROJECT" ]] && PROJECT_ARGS=(--project "$PROJECT")
MESSAGE="$(git log -1 --format='%h %s')"
[[ $DIRTY == true ]] && MESSAGE="$MESSAGE (pohon kotor)"

if [[ -n "$CHANNEL" ]]; then
  firebase hosting:channel:deploy "$CHANNEL" --expires 7d ${PROJECT_ARGS[@]+"${PROJECT_ARGS[@]}"}
else
  firebase deploy --only hosting -m "$MESSAGE" ${PROJECT_ARGS[@]+"${PROJECT_ARGS[@]}"}
fi
