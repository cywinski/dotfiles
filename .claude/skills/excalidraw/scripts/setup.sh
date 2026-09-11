#!/usr/bin/env bash
# ABOUTME: One-time setup for the excalidraw skill — installs build deps, bundles the
# browser payload with esbuild, then prunes back to the runtime-only dependency.
set -euo pipefail
cd "$(dirname "$0")/.."
echo "[excalidraw-skill] installing build dependencies..."
npm install --silent --no-audit --no-fund
echo "[excalidraw-skill] bundling browser payload..."
npm run --silent build
echo "[excalidraw-skill] pruning build dependencies..."
npm prune --omit=dev --silent --no-audit --no-fund
echo "[excalidraw-skill] done: $(du -h scripts/bundle.js | cut -f1) bundle, $(du -sh node_modules | cut -f1) node_modules"
