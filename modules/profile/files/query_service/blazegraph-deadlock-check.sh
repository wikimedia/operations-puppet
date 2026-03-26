#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# Blazegraph deadlock auto-remediation (T242453)
#
# Checks local Blazegraph health via two metrics:
#   1. JVM thread count (from JMX exporter) — detects deadlocks
#   2. Update lag (from Python Blazegraph exporter) — detects stalled updaters
#
# Restarts blazegraph if either metric exceeds its threshold.
# Both checks share a single cooldown to prevent restart storms.
#
# Metrics are fetched with retry + exponential backoff to handle transient
# exporter unavailability (e.g., during GC pressure). If all retries are
# exhausted, the check is skipped (exit 0) — Prometheus scrape-target
# monitoring is the backstop for permanently broken exporters.
#
# Managed by Puppet - profile::query_service::blazegraph_deadlock_remediation

set -euo pipefail

CONFIG_FILE="${1:?Usage: $0 <config-file>}"

# shellcheck source=/dev/null
. "$CONFIG_FILE"

log() {
    local msg
    msg="$(date -u '+%Y-%m-%dT%H:%M:%SZ') $(hostname -s) ${SERVICE}: $*"
    echo "$msg" >> "$LOG_FILE"
    logger -t "wdqs-deadlock-remediation[${SERVICE}]" "$*"
}

# Fetch a metric value with retry + exponential backoff.
# Usage: fetch_metric <url> <metric_name_regex> <description>
# Prints the integer value on success, empty string on failure.
fetch_metric() {
    local url="$1" pattern="$2" desc="$3"
    local attempt=0 value=""

    while [ "$attempt" -le "$MAX_RETRIES" ]; do
        # || true: prevent set -e from killing the script on curl failure
        value=$(curl -sf --max-time 5 "$url" \
            | awk "/${pattern}/ {printf \"%d\", \$2}") || true

        # Validate: must be a positive integer (awk %d converts floats/sci
        # notation to int; NaN/garbage becomes 0)
        if [[ "$value" =~ ^[0-9]+$ ]] && [ "$value" -gt 0 ]; then
            echo "$value"
            return 0
        fi

        if [ "$attempt" -lt "$MAX_RETRIES" ]; then
            local delay=$(( RETRY_BASE_DELAY * (2 ** attempt) ))
            log "RETRY: failed to fetch ${desc} (attempt $((attempt + 1))/${MAX_RETRIES}), retrying in ${delay}s"
            sleep "$delay"
        fi
        attempt=$((attempt + 1))
    done

    log "ERROR: Failed to fetch ${desc} from ${url} after $((MAX_RETRIES + 1)) attempts"
    return 1
}

do_restart() {
    local reason="$1"
    log "RESTART: ${reason}, restarting ${SERVICE}"
    systemctl restart "$SERVICE"
    touch "$COOLDOWN_FILE"
    log "RESTART: ${SERVICE} restart issued successfully"
}

# --- Main ---

# Check cooldown FIRST — if we recently restarted, skip all metric fetches.
# Avoids burning through retry backoff loops when exporters are still booting
# after a restart. The next timer tick (5 min) will re-check.
if [ -f "$COOLDOWN_FILE" ]; then
    LAST=$(stat -c %Y "$COOLDOWN_FILE")
    NOW=$(date +%s)
    if [ $((NOW - LAST)) -lt "$COOLDOWN_SECONDS" ]; then
        REMAINING=$(( (COOLDOWN_SECONDS - (NOW - LAST)) / 60 ))
        log "COOLDOWN: active (${REMAINING}m remaining), skipping checks"
        exit 0
    fi
fi

NEED_RESTART=""

# --- Check 1: Thread count (deadlock detection) ---
# || true: fetch_metric returns 1 on exhausted retries; don't let set -e exit
THREAD_COUNT=$(fetch_metric "$METRICS_URL" "^jvm_threads_current " "jvm_threads_current") || true

if [ -n "$THREAD_COUNT" ]; then
    if [ "$THREAD_COUNT" -ge "$THRESHOLD" ]; then
        NEED_RESTART="threads=${THREAD_COUNT} (>=${THRESHOLD})"
    fi
fi

# --- Check 2: Update lag (stalled updater detection) ---
# Only if UPDATER_METRICS_URL is configured (empty = skip, e.g. categories)
if [ -z "$NEED_RESTART" ] && [ -n "$UPDATER_METRICS_URL" ]; then
    LAST_UPDATED=$(fetch_metric "$UPDATER_METRICS_URL" "^blazegraph_lastupdated " "blazegraph_lastupdated") || true

    if [ -n "$LAST_UPDATED" ]; then
        NOW=$(date +%s)
        LAG=$(( NOW - LAST_UPDATED ))
        # Guard against clock skew (negative lag)
        if [ "$LAG" -lt 0 ]; then
            log "WARNING: blazegraph_lastupdated is in the future (lag=${LAG}s), skipping lag check"
        elif [ "$LAG" -gt "$LAG_THRESHOLD" ]; then
            NEED_RESTART="lag=${LAG}s (>${LAG_THRESHOLD}s)"
        fi
    fi
fi

if [ -n "$NEED_RESTART" ]; then
    # Note: cooldown stamp is written AFTER systemctl restart succeeds. If the
    # restart fails (set -e exits the script), cooldown is intentionally NOT
    # armed so the next timer run will retry.
    do_restart "$NEED_RESTART"
else
    exit 0
fi
