#!/usr/bin/env bash
# verify_original.sh — confirms the baseline artifact is byte-for-byte unchanged.
# Run from the repository root. Exit 0 = unchanged.
set -euo pipefail
cd "$(dirname "$0")/../../.."
echo "Repository root: $(pwd)"
sha256sum -c MR-SPICY/original/checksums/original-ipa.sha256
sha256sum -c MR-SPICY/original/checksums/logo.sha256
( cd MR-SPICY/original/manifests && sha256sum -c ../checksums/manifests.sha256 )
echo "BASELINE INTEGRITY: PASS"
