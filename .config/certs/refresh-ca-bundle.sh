#!/usr/bin/env bash
#
# Rebuild the CA bundle used by tools that do not consult the macOS trust store.
#
# Go binaries (gh, and most Go CLIs) evaluate certificates without honoring the
# admin trust settings that corporate roots rely on, so a TLS-inspecting agent
# such as DefensX makes them fail with "x509: failed to verify certificate"
# while /usr/bin/curl succeeds. Handing those tools an explicit bundle that
# contains the same roots fixes it.
#
# The bundle is a point-in-time snapshot: Apple ships root updates through OS
# updates and MDM can push new corporate roots at any time. Re-run this script
# if TLS starts failing again after either of those.
#
# Emits nothing on success beyond a one-line summary; safe to re-run.

set -euo pipefail

BUNDLE_DIR="${HOME}/.config/certs"
BUNDLE="${BUNDLE_DIR}/ca-bundle.pem"
TMP="$(mktemp)"
trap 'rm -f "${TMP}"' EXIT

# Apple's built-in roots.
security find-certificate -a -p \
  /System/Library/Keychains/SystemRootCertificates.keychain >>"${TMP}"

# Admin/MDM-added roots (corporate PKI, TLS-inspection roots). Present only on
# managed machines, so a failure here is not fatal.
security find-certificate -a -p /Library/Keychains/System.keychain >>"${TMP}" || true

if ! grep -q "BEGIN CERTIFICATE" "${TMP}"; then
  echo "refresh-ca-bundle: no certificates extracted, refusing to write" >&2
  exit 1
fi

mkdir -p "${BUNDLE_DIR}"
install -m 644 "${TMP}" "${BUNDLE}"
echo "refresh-ca-bundle: wrote ${BUNDLE} ($(grep -c 'BEGIN CERTIFICATE' "${BUNDLE}") certificates)"
