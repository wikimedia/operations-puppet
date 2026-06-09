#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Discard stale pending subscription requests (T353891).

Unconfirmed subscription requests (token_owner 'subscriber') from bots and spam
accumulate on busy lists and are not evicted by Core's task runner, so they pile
up. A large backlog makes Postorius' list-summary page fetch the whole
collection and time out. This janitor discards subscriber-owned subscription
requests older than a given number of days.

Modeled on discard_held_messages.py.
"""

import argparse
import csv
import datetime
import os
import sys
import tempfile
import time

from mailmanclient import Client
import wmflib.config


# Only ever discard requests awaiting the *subscriber's* own confirmation, never
# moderator-pending ones (discarding those would reject a real subscription).
SAFE_TOKEN_OWNER = "subscriber"
SAFE_REQUEST_TYPE = "subscription"

# Refuse to run with a smaller age: pending_request_life is 3d, so anything
# younger may still be a legitimately in-flight confirmation.
MIN_DAYS = 3

# Columns written to the --record TSV (keys of a mailmanclient request dict).
RECORD_FIELDS = ["request_date", "list_id", "email", "display_name", "token"]

# Prefix for the Prometheus textfile-collector metrics.
METRIC_PREFIX = "mailman_stale_subs_"


def _age_days(value):
    days = int(value)
    if days < MIN_DAYS:
        raise argparse.ArgumentTypeError(f"must be >= {MIN_DAYS}")
    return days


def parse_args():
    parser = argparse.ArgumentParser(
        description="Discard stale pending subscription requests after a certain amount of days")
    parser.add_argument("days", type=_age_days,
                        help=f"Discard requests older than this many days (minimum {MIN_DAYS}).")
    parser.add_argument("--dry-run", action="store_true", help="Do not actually discard requests")
    parser.add_argument("--list", dest="lists", action="append", metavar="FQDN_LISTNAME",
                        help="Only process this list (repeatable). Default: all lists.")
    parser.add_argument("--record", metavar="FILE",
                        help="Write a TSV record of every processed request to FILE. "
                             "Works with or without --dry-run.")
    parser.add_argument("--prom-file", metavar="FILE",
                        help="Opt-in: write/refresh Prometheus textfile metrics at FILE "
                             "(counters are incremented, not overwritten).")
    return parser.parse_args()


def get_client() -> Client:
    cfg = wmflib.config.load_ini_config("/etc/mailman3/mailman.cfg")
    return Client(
        "http://localhost:8001/3.1",
        cfg["webservice"]["admin_user"],
        cfg["webservice"]["admin_pass"]
    )


def parse_request_date(value):
    """Parse a request_date into a naive UTC datetime (coerce aware -> naive)."""
    dt = datetime.datetime.fromisoformat(value)
    if dt.tzinfo is not None:
        dt = dt.astimezone(datetime.timezone.utc).replace(tzinfo=None)
    return dt


def _read_prev_counters(path):
    """Parse an existing .prom file into {series: float}; tolerate absence/garbage."""
    values = {}
    try:
        with open(path) as fh:
            for line in fh:
                line = line.strip()
                if not line or line.startswith("#"):
                    continue
                key, _, val = line.rpartition(" ")
                try:
                    values[key] = float(val)
                except ValueError:
                    continue
    except FileNotFoundError:
        pass
    return values


def write_metrics(path, *, success, discarded, errors, pending_seen,
                  lists_processed, duration, dry_run, timestamp):
    """Update the Prometheus textfile-collector file at path.

    Cumulative counters (runs_total, discarded_total, errors_total) are read
    back from the existing file and incremented, so history survives across
    runs; gauges reflect the last run only. Dry-runs update gauges (with
    last_run_dry_run=1) but never move the cumulative counters. Written
    atomically via a temp file + rename.
    """
    p = METRIC_PREFIX
    prev = _read_prev_counters(path)
    runs_success = prev.get(p + 'runs_total{result="success"}', 0.0)
    runs_failure = prev.get(p + 'runs_total{result="failure"}', 0.0)
    discarded_total = prev.get(p + "discarded_total", 0.0)
    errors_total = prev.get(p + "errors_total", 0.0)

    if not dry_run:
        if success:
            runs_success += 1
        else:
            runs_failure += 1
        discarded_total += discarded
        errors_total += errors

    lines = [
        f"# HELP {p}runs_total Real (non-dry-run) janitor runs by result.",
        f"# TYPE {p}runs_total counter",
        f'{p}runs_total{{result="success"}} {int(runs_success)}',
        f'{p}runs_total{{result="failure"}} {int(runs_failure)}',
        f"# HELP {p}discarded_total Stale requests discarded across all real runs.",
        f"# TYPE {p}discarded_total counter",
        f"{p}discarded_total {int(discarded_total)}",
        f"# HELP {p}errors_total Errors encountered across all real runs.",
        f"# TYPE {p}errors_total counter",
        f"{p}errors_total {int(errors_total)}",
        f"# HELP {p}last_run_timestamp_seconds Unix time of the last run.",
        f"# TYPE {p}last_run_timestamp_seconds gauge",
        f"{p}last_run_timestamp_seconds {timestamp:.0f}",
        f"# HELP {p}last_run_success Last run completed with no errors (1) or not (0).",
        f"# TYPE {p}last_run_success gauge",
        f"{p}last_run_success {1 if success else 0}",
        f"# HELP {p}last_run_discarded Requests discarded in the last run.",
        f"# TYPE {p}last_run_discarded gauge",
        f"{p}last_run_discarded {int(discarded)}",
        f"# HELP {p}last_run_errors Errors during the last run.",
        f"# TYPE {p}last_run_errors gauge",
        f"{p}last_run_errors {int(errors)}",
        f"# HELP {p}last_run_pending_seen Subscriber subscription requests seen this run.",
        f"# TYPE {p}last_run_pending_seen gauge",
        f"{p}last_run_pending_seen {int(pending_seen)}",
        f"# HELP {p}last_run_lists_processed Lists with pending requests processed.",
        f"# TYPE {p}last_run_lists_processed gauge",
        f"{p}last_run_lists_processed {int(lists_processed)}",
        f"# HELP {p}last_run_duration_seconds Duration of the last run in seconds.",
        f"# TYPE {p}last_run_duration_seconds gauge",
        f"{p}last_run_duration_seconds {duration:.3f}",
        f"# HELP {p}last_run_dry_run Last run was a dry-run (1) or real (0).",
        f"# TYPE {p}last_run_dry_run gauge",
        f"{p}last_run_dry_run {1 if dry_run else 0}",
    ]
    content = "\n".join(lines) + "\n"

    directory = os.path.dirname(path) or "."
    fd, tmp = tempfile.mkstemp(dir=directory, prefix=".discard_stale_sub_mailman.", suffix=".tmp")
    try:
        with os.fdopen(fd, "w") as fh:
            fh.write(content)
        os.chmod(tmp, 0o644)
        os.replace(tmp, path)
    except BaseException:
        try:
            os.unlink(tmp)
        except OSError:
            pass
        raise


def discard_request(mlist, request, args, writer):
    """Discard (or, in dry-run, report) one stale request, and record it."""
    label = f"{request['email']} ({request['request_date']}) from {mlist.fqdn_listname}"
    if args.dry_run:
        print(f"Would have discarded {label}")
    else:
        mlist.moderate_request(request["token"], "discard")
        print(f"Discarded {label}")
    # Record after the action so a real run only logs successful discards;
    # in dry-run it logs everything that would be discarded.
    if writer is not None:
        writer.writerow(request)


def main():
    args = parse_args()
    if args.dry_run:
        print("Dry-run mode enabled")
    start = time.time()
    now_utc = datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None)
    cutoff = now_utc - datetime.timedelta(days=args.days)

    discarded = 0
    errors = 0
    pending_seen = 0
    lists_processed = 0
    completed = False

    record_fh = open(args.record, "w", newline="") if args.record else None
    try:
        writer = None
        if record_fh is not None:
            # extrasaction='ignore' drops the extra request keys (token_owner,
            # http_etag, ...); missing keys fall back to ''.
            writer = csv.DictWriter(record_fh, fieldnames=RECORD_FIELDS,
                                    delimiter="\t", extrasaction="ignore")
            writer.writeheader()

        client = get_client()
        if args.lists:
            mlists = [client.get_list(name) for name in args.lists]
        else:
            mlists = client.get_lists()
        for mlist in mlists:
            try:
                # Cheap count first: skip lists with no pending requests so we
                # never pay for the expensive, unpaginated full fetch needlessly.
                if mlist.get_requests_count() == 0:
                    continue
                # Filter server-side: the client dict has no 'type' key, so the
                # type/owner distinction must come from the API, not from us.
                requests = mlist.get_requests(token_owner=SAFE_TOKEN_OWNER,
                                              request_type=SAFE_REQUEST_TYPE)
                pending_seen += len(requests)
                lists_processed += 1
                for request in requests:
                    # Defensive: re-check the owner (the key is present) in case
                    # the server ignores the filter; never discard moderator ones.
                    if request.get("token_owner") != SAFE_TOKEN_OWNER:
                        continue
                    if parse_request_date(request["request_date"]) > cutoff:
                        continue
                    try:
                        discard_request(mlist, request, args, writer)
                        discarded += 1
                        if record_fh is not None:
                            record_fh.flush()
                    except Exception as exc:
                        # One bad token must not abort the whole purge.
                        errors += 1
                        print(f"ERROR discarding {request.get('email')} from "
                              f"{mlist.fqdn_listname}: {exc}", file=sys.stderr)
            except Exception as exc:
                # A failing list must not abort the others.
                errors += 1
                name = getattr(mlist, "fqdn_listname", mlist)
                print(f"ERROR processing {name}: {exc}", file=sys.stderr)
        completed = True
    finally:
        if record_fh is not None:
            record_fh.close()
        if args.prom_file:
            try:
                write_metrics(
                    args.prom_file,
                    success=(completed and errors == 0),
                    discarded=discarded,
                    errors=errors,
                    pending_seen=pending_seen,
                    lists_processed=lists_processed,
                    duration=time.time() - start,
                    dry_run=args.dry_run,
                    timestamp=time.time(),
                )
            except Exception as exc:
                print(f"WARNING: could not write metrics to {args.prom_file}: {exc}",
                      file=sys.stderr)

    if not completed or errors:
        sys.exit(1)


if __name__ == "__main__":
    main()
