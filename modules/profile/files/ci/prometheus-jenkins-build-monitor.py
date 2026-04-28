#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0

from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys
import tempfile
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Iterable, Optional

SEARCH_ROOT = Path("/srv/jenkins/builds")
OUTPUT_FILE = Path("/var/lib/prometheus/node.d/jenkins_build_monitor.prom")
STABLE_SECONDS = 60
FILE_NAME = "log"
MATCH_TEXT = "GnuTLS recv error"
RETRY_TEXT = "Retry scheduled"
RETRY_WINDOW_LINES = 5

LAST_RUN_METRIC = "jenkins_build_monitor_last_run_timestamp_seconds"
SCAN_CURSOR_METRIC = "jenkins_build_monitor_scan_cursor_timestamp_seconds"

COUNTER_METRICS = {
    "jenkins_build_monitor_failed_builds_total": (
        "Cumulative number of Jenkins builds that finished with FAILURE."
    ),
    "jenkins_build_monitor_failed_builds_due_to_gnutls_total": (
        "Cumulative number of Jenkins builds that finished with FAILURE and had "
        "an unretried GnuTLS recv error."
    ),
    "jenkins_build_monitor_gnutls_retried_builds_total": (
        "Cumulative number of Jenkins builds with a GnuTLS recv error followed "
        "by a retry within the configured line window."
    ),
    "jenkins_build_monitor_successful_builds_without_retry_total": (
        "Cumulative number of Jenkins builds that finished with SUCCESS and had no retry."
    ),
}

GAUGE_METRICS = {
    LAST_RUN_METRIC: "Unix timestamp of the last Jenkins build monitor run.",
    SCAN_CURSOR_METRIC: (
        "Unix timestamp up to which Jenkins build logs have been considered stable and scanned."
    ),
}

ALL_METRIC_NAMES = set(COUNTER_METRICS) | set(GAUGE_METRICS)


@dataclass
class State:
    counters: Dict[str, int]
    scan_cursor: int
    bootstrap: bool


@dataclass
class LogAnalysis:
    finished_status: Optional[str]
    has_retry: bool
    has_retried_gnutls: bool
    has_unretried_gnutls: bool


def parse_positive_int(value: str) -> int:
    try:
        parsed = int(value)
    except ValueError:
        raise argparse.ArgumentTypeError("expected a positive integer") from None

    if parsed < 1:
        raise argparse.ArgumentTypeError("expected a positive integer")

    return parsed


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Export Jenkins build log counters for Prometheus node_exporter."
    )
    parser.add_argument("--builds-dir", type=Path, default=SEARCH_ROOT)
    parser.add_argument("--outfile", type=Path, default=OUTPUT_FILE)
    parser.add_argument("--stable-seconds", type=parse_positive_int, default=STABLE_SECONDS)
    return parser.parse_args()


def read_metric_values(path: Path) -> Dict[str, float]:
    metric_values: Dict[str, float] = {}

    try:
        lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    except FileNotFoundError:
        return metric_values

    for line in lines:
        line = line.strip()
        if not line or line.startswith("#"):
            continue

        fields = line.split()
        if len(fields) < 2:
            continue

        metric_name = fields[0].split("{", 1)[0]
        if metric_name not in ALL_METRIC_NAMES:
            continue

        try:
            metric_values[metric_name] = float(fields[1])
        except ValueError:
            continue

    return metric_values


def metric_int_value(metric_values: Dict[str, float], metric_name: str, default: int = 0) -> int:
    if metric_name not in metric_values:
        return default

    try:
        return max(0, int(metric_values[metric_name]))
    except (OverflowError, ValueError):
        return default


def load_state(outfile: Path) -> State:
    metric_values = read_metric_values(outfile)
    counters = {
        metric_name: metric_int_value(metric_values, metric_name)
        for metric_name in COUNTER_METRICS
    }

    if SCAN_CURSOR_METRIC in metric_values:
        scan_cursor = metric_int_value(metric_values, SCAN_CURSOR_METRIC)
        return State(counters=counters, scan_cursor=scan_cursor, bootstrap=False)

    if LAST_RUN_METRIC in metric_values:
        scan_cursor = metric_int_value(metric_values, LAST_RUN_METRIC)
        return State(counters=counters, scan_cursor=scan_cursor, bootstrap=False)

    return State(counters=counters, scan_cursor=0, bootstrap=True)


def render_metrics(counters: Dict[str, int], last_run: int, scan_cursor: int) -> str:
    lines = []

    for metric_name, help_text in GAUGE_METRICS.items():
        lines.append(f"# HELP {metric_name} {help_text}")
        lines.append(f"# TYPE {metric_name} gauge")
        if metric_name == LAST_RUN_METRIC:
            lines.append(f"{metric_name} {last_run}")
        else:
            lines.append(f"{metric_name} {scan_cursor}")

    for metric_name, help_text in COUNTER_METRICS.items():
        lines.append(f"# HELP {metric_name} {help_text}")
        lines.append(f"# TYPE {metric_name} counter")
        lines.append(f"{metric_name} {counters.get(metric_name, 0)}")

    return "\n".join(lines) + "\n"


def write_metrics(outfile: Path, counters: Dict[str, int], last_run: int, scan_cursor: int) -> None:
    tmp_path = None
    try:
        fd, tmp_path = tempfile.mkstemp(prefix=f".{outfile.name}.", dir=outfile.parent)
        with os.fdopen(fd, "w", encoding="utf-8") as tmp_file:
            tmp_file.write(render_metrics(counters, last_run, scan_cursor))
            tmp_file.flush()
            os.fsync(tmp_file.fileno())

        os.chmod(tmp_path, 0o644)
        os.replace(tmp_path, outfile)
    finally:
        if tmp_path is not None:
            try:
                os.unlink(tmp_path)
            except FileNotFoundError:
                pass


def iter_candidate_paths(
    root: Path,
    changed_after_epoch: int,
    changed_before_epoch: int,
) -> Iterable[Path]:
    finder = shutil.which("find")
    if finder is not None:
        yield from iter_candidate_paths_with_find(
            root,
            changed_after_epoch,
            changed_before_epoch,
            finder,
        )
        return

    yield from iter_candidate_paths_with_python(root, changed_after_epoch, changed_before_epoch)


def iter_candidate_paths_with_find(
    root: Path,
    changed_after_epoch: int,
    changed_before_epoch: int,
    finder: str,
) -> Iterable[Path]:
    command = [
        finder,
        str(root),
        "-type",
        "f",
        "-name",
        FILE_NAME,
        "-newermt",
        f"@{changed_after_epoch}",
        "!",
        "-newermt",
        f"@{changed_before_epoch}",
        "-print0",
    ]
    completed = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)

    if completed.returncode != 0:
        error_message = completed.stderr.decode("utf-8", errors="replace").strip()
        raise RuntimeError(error_message or f"{finder} exited with {completed.returncode}")

    for raw_path in completed.stdout.split(b"\0"):
        if raw_path:
            yield Path(raw_path.decode("utf-8", errors="surrogateescape"))


def iter_candidate_paths_with_python(
    root: Path,
    changed_after_epoch: int,
    changed_before_epoch: int,
) -> Iterable[Path]:
    changed_after_ns = changed_after_epoch * 1_000_000_000
    changed_before_ns = changed_before_epoch * 1_000_000_000
    stack = [root]

    while stack:
        current = stack.pop()

        try:
            with os.scandir(current) as entries:
                for entry in entries:
                    try:
                        if entry.is_dir(follow_symlinks=False):
                            stack.append(Path(entry.path))
                            continue

                        if entry.name != FILE_NAME or not entry.is_file(follow_symlinks=False):
                            continue

                        entry_stat = entry.stat(follow_symlinks=False)
                    except FileNotFoundError:
                        continue
                    except OSError as exc:
                        print(f"warning: unable to inspect {entry.path}: {exc}", file=sys.stderr)
                        continue

                    if changed_after_ns < entry_stat.st_mtime_ns <= changed_before_ns:
                        yield Path(entry.path)
        except FileNotFoundError:
            continue
        except OSError as exc:
            print(f"warning: unable to scan {current}: {exc}", file=sys.stderr)


def get_mtime_ns(path: Path) -> Optional[int]:
    try:
        return path.stat().st_mtime_ns
    except FileNotFoundError:
        return None
    except OSError as exc:
        print(f"warning: unable to stat {path}: {exc}", file=sys.stderr)
        return None


def finished_status_from_line(line: str) -> Optional[str]:
    stripped_line = line.strip()
    if not stripped_line.lower().startswith("finished:"):
        return None

    status = stripped_line.partition(":")[2].strip()
    if not status:
        return None

    return status.split(None, 1)[0].upper()


def classify_gnutls_lines(gnutls_lines: list[int], retry_lines: list[int]) -> tuple[bool, bool]:
    has_retried = False
    has_unretried = False
    retry_index = 0

    for gnutls_line in gnutls_lines:
        while retry_index < len(retry_lines) and retry_lines[retry_index] <= gnutls_line:
            retry_index += 1

        if (
            retry_index < len(retry_lines)
            and retry_lines[retry_index] <= gnutls_line + RETRY_WINDOW_LINES
        ):
            has_retried = True
        else:
            has_unretried = True

    return has_retried, has_unretried


def analyze_log(path: Path) -> Optional[LogAnalysis]:
    finished_status = None
    gnutls_lines: list[int] = []
    retry_lines: list[int] = []
    match_text = MATCH_TEXT.lower()
    retry_text = RETRY_TEXT.lower()

    try:
        with path.open("r", encoding="utf-8", errors="replace") as log_file:
            for line_number, line in enumerate(log_file, start=1):
                status = finished_status_from_line(line)
                if status is not None:
                    finished_status = status

                lowered_line = line.lower()
                if match_text in lowered_line:
                    gnutls_lines.append(line_number)
                if retry_text in lowered_line:
                    retry_lines.append(line_number)
    except FileNotFoundError:
        return None
    except OSError as exc:
        print(f"warning: unable to read {path}: {exc}", file=sys.stderr)
        return None

    has_retried_gnutls, has_unretried_gnutls = classify_gnutls_lines(
        gnutls_lines,
        retry_lines,
    )
    return LogAnalysis(
        finished_status=finished_status,
        has_retry=bool(retry_lines),
        has_retried_gnutls=has_retried_gnutls,
        has_unretried_gnutls=has_unretried_gnutls,
    )


def update_counters(counters: Dict[str, int], analysis: LogAnalysis) -> None:
    if analysis.finished_status == "FAILURE":
        counters["jenkins_build_monitor_failed_builds_total"] += 1
        if analysis.has_unretried_gnutls:
            counters["jenkins_build_monitor_failed_builds_due_to_gnutls_total"] += 1

    if analysis.has_retried_gnutls:
        counters["jenkins_build_monitor_gnutls_retried_builds_total"] += 1

    if analysis.finished_status == "SUCCESS" and not analysis.has_retry:
        counters["jenkins_build_monitor_successful_builds_without_retry_total"] += 1


def scan_build_logs(
    builds_dir: Path,
    counters: Dict[str, int],
    changed_after_epoch: int,
    changed_before_epoch: int,
) -> None:
    changed_after_ns = changed_after_epoch * 1_000_000_000
    changed_before_ns = changed_before_epoch * 1_000_000_000

    for path in iter_candidate_paths(builds_dir, changed_after_epoch, changed_before_epoch):
        mtime_ns = get_mtime_ns(path)
        if mtime_ns is None:
            continue

        if not changed_after_ns < mtime_ns <= changed_before_ns:
            continue

        analysis = analyze_log(path)
        if analysis is not None:
            update_counters(counters, analysis)


def run(args: argparse.Namespace) -> int:
    now = int(time.time())
    state = load_state(args.outfile)
    scan_cursor = max(state.scan_cursor, now - args.stable_seconds)

    if state.bootstrap:
        write_metrics(args.outfile, state.counters, now, scan_cursor)
        return 0

    if not args.builds_dir.is_dir():
        raise RuntimeError(f"{args.builds_dir} does not exist or is not a directory")

    if scan_cursor > state.scan_cursor:
        scan_build_logs(args.builds_dir, state.counters, state.scan_cursor, scan_cursor)

    write_metrics(args.outfile, state.counters, now, scan_cursor)
    return 0


def main() -> int:
    args = parse_args()

    try:
        return run(args)
    except RuntimeError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
