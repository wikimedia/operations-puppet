#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# Run every Lift Wing httpbb suite for one environment, one suite at a time.
# Each suite runs on its own so the result is reported per suite. The script
# returns non-zero if any suite fails.
#
# Per-suite settings come from service_availability.conf (next to this script),
# so this script has no service-specific logic. That file declares, per suite:
#   - the datacentres a suite runs in (some isvcs are deployed to one
#     datacentre only); a suite is skipped in a datacentre where it is not
#     available, instead of failing.
#   - an optional host and port override for suites that do not use the shared
#     inference ingress (for example recommendation-api-ng, which has its own
#     discovery record and port).
# A suite that is not listed uses the shared inference ingress and runs in
# every datacentre.
#
# The Lift Wing httpbb suites are deployed by profile::httpbb; this helper is
# not deployed, so copy it to a host (or set HTTPBB_LIFTWING_DIR) to run it.
#
# Usage: ./run_all.sh [production|staging] [codfw|eqiad]
#   env default: production
#   dc  default: codfw  (staging is codfw only; the dc argument is ignored)
#
# Set HTTPBB_LIFTWING_DIR to run against a suite tree other than the default
# /srv/deployment/httpbb-tests/liftwing (for example a local copy under /tmp).

set -u

BASE_DIR="${HTTPBB_LIFTWING_DIR:-/srv/deployment/httpbb-tests/liftwing}"
AVAIL_FILE="${BASE_DIR}/service_availability.conf"

ENV="${1:-production}"
DC="${2:-codfw}"

case "${ENV}" in
    production)
        shared_host="inference.svc.${DC}.wmnet"
        ;;
    staging)
        # Staging runs in codfw only; ignore the dc argument.
        DC="codfw"
        shared_host="inference-staging.svc.codfw.wmnet"
        ;;
    *)
        echo "Unknown environment: ${ENV} (use production or staging)" >&2
        exit 2
        ;;
esac

DIR="${BASE_DIR}/${ENV}"
rc=0
passed=0
failed=0
skipped=0

# Echo the settings fields for suite ${1} from the availability file (the line
# with the leading suite name removed), or nothing when the suite is not listed.
suite_fields() {
    [ -f "${AVAIL_FILE}" ] || return 0
    grep -v '^[[:space:]]*#' "${AVAIL_FILE}" 2>/dev/null \
        | grep -E "^[[:space:]]*$1[[:space:]]" \
        | sed 's/^[[:space:]]*[^[:space:]]*[[:space:]]*//' \
        | head -n1
}

# Run one suite and report a single PASS/FAIL line. Show the httpbb output
# only when the suite fails.
run_suite() {
    suite_file="$1"
    suite_host="$2"
    suite_port="$3"
    name=$(basename "${suite_file}" .yaml)
    if out=$(httpbb "${suite_file}" --host "${suite_host}" --https_port "${suite_port}" --retry_on_timeout 2>&1); then
        echo "PASS  ${name}"
        passed=$((passed + 1))
    else
        echo "FAIL  ${name}"
        echo "${out}" | sed 's/^/      /'
        failed=$((failed + 1))
        rc=1
    fi
}

echo "== Lift Wing ${ENV} suites =="

for f in "${DIR}"/*.yaml; do
    name=$(basename "${f}" .yaml)

    # Parse this suite's settings from the availability file.
    # Fields are whitespace-separated tokens after the suite name:
    #   - a bare "codfw" or "eqiad" restricts the suite to those datacentres;
    #   - port=<n>            overrides the https port (default 30443);
    #   - host_production=<h> overrides the host in production;
    #   - host_staging=<h>    overrides the host in staging.
    avail_dcs=""
    suite_port="30443"
    host_production=""
    host_staging=""
    for tok in $(suite_fields "${name}"); do
        case "${tok}" in
            codfw|eqiad)       avail_dcs="${avail_dcs} ${tok}" ;;
            port=*)            suite_port="${tok#port=}" ;;
            host_production=*)  host_production="${tok#host_production=}" ;;
            host_staging=*)     host_staging="${tok#host_staging=}" ;;
        esac
    done

    # Skip the suite when it is restricted to datacentres that exclude this one.
    if [ -n "${avail_dcs}" ]; then
        available=0
        for d in ${avail_dcs}; do
            [ "${d}" = "${DC}" ] && available=1
        done
        if [ "${available}" -ne 1 ]; then
            echo "SKIP  ${name} (not deployed in ${DC})"
            skipped=$((skipped + 1))
            continue
        fi
    fi

    # Use the per-suite host override for this environment, else the shared
    # inference ingress.
    if [ "${ENV}" = "staging" ]; then
        suite_host="${host_staging:-${shared_host}}"
    else
        suite_host="${host_production:-${shared_host}}"
    fi

    run_suite "${f}" "${suite_host}" "${suite_port}"
done

echo "== Done: ${passed} passed, ${failed} failed, ${skipped} skipped =="
exit "${rc}"
