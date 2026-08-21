#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Traces Toolforge NFS usage for the infra-tracing project.

# Dependencies:

    * linux-headers-$(uname -r)
    * python3-bpfcc

# Configuration:

It requires an INI file to be passed as the only CLI argument (defaults to
/etc/infra-tracing-nfs.ini) with a content of the form:

    [nfs]
    username = username
    password = password
    # Optional keys, the values here are their default values
    # URL of the Loki instance where to push the logs
    loki_url = https://localhost:30004/
    # Max seconds to buffer logs before pushing them to loki (float)
    buffer_secs = 30.0
    # Max lines of log to buffer before pushing them to loki (int)
    buffer_lines = 300
    # Name of the level in the Python's logging module to use
    log_level = INFO
    # Set it to true when inside a toolforge kubernetes worker node
    in_k8s_node = false

# Current NFS symlinked dirs:

/data/project -> /mnt/nfs/nfs-01-toolsbeta-project
/data/scratch -> /mnt/nfs/secondary-scratch
/home -> /mnt/nfs/nfs-01-toolsbeta-home
/public/dumps/pagecounts-raw -> /mnt/nfs/dumps/other/pagecounts-raw
/public/dumps/public -> /mnt/nfs/dumps
/public/dumps/pagecounts-all-sites ->
  /mnt/nfs/dumps/other/pagecounts-all-sites
/public/dumps/incr -> /mnt/nfs/dumps/other/incr
/public/dumps/pageviews -> /mnt/nfs/dumps/other/pageviews

"""

import argparse
import configparser
import dataclasses
import logging
import pwd
import queue
import threading
import time
from collections import Counter, defaultdict
from datetime import datetime, timedelta, timezone
from functools import cache
from pathlib import Path
from pprint import pformat
from socket import gethostname
from typing import Any, Optional

import urllib3
from bcc import BPF  # type: ignore[import-not-found]  # not available in PyPI
from requests import Session
from requests.exceptions import RequestException

logger = logging.getLogger(__name__)

BASE_PATH = "/mnt/nfs"
TOOLFORGE_PROJECTS = ("tools", "toolsbeta")
BPF_PROGRAM = """// BPF program to trace open files that match the NFS mountpoints and symlinks
#include <uapi/linux/ptrace.h>
#include <linux/sched.h>
#include <linux/types.h>

#define PATH_MAX_LEN 256  // Keep it well under the 512 limit
#define MAX_PREFIX_LEN 9  // Max lenght of the longest prefix to check

// Defining them as static they go into the .rodata and the verifier is sure they are immutable
static const char filter_mnt[]    = "/mnt/nfs/";
static const char filter_home[]   = "/home/";
static const char filter_data[]   = "/data/";
static const char filter_public[] = "/public/";

// Base struct sent to user space
struct nfs_event {
    u32 pid;
    u32 uid;
    char path[PATH_MAX_LEN];
};

// Ring buffer for events
BPF_RINGBUF_OUTPUT(nfs_events, 256); // 256 pages = 1 MB
// Counter for dropped events
BPF_ARRAY(dropped_events, u64, 1);

// With bcc we can't use libbpf's bpf_strncmp so have to compare manually
static __always_inline int starts_with(
    const char *s,
    const char *prefix,
    int len) {
// Unroll converts this into single instructions at compile time
#pragma unroll
    for (int i = 0; i < MAX_PREFIX_LEN; i++) {
        if (i >= len)
            return 1;
        if (s[i] != prefix[i])
            return 0;
    }
    return 1;
}

// Shared logic for openat / openat2
static __always_inline void trace_nfs(void *ctx, const char *filename) {
    if (!filename) {
        return;
    }
    u32 uid = (u32)bpf_get_current_uid_gid();  // To resolve the user ID into a name
    #if SKIP_ROOT
        if (uid == 0) {  // Skip root when inside toolforge kubernetes nodes
            return;
        }
    #endif

    struct nfs_event *e;

    // Get a new event in the ring buffer
    e = nfs_events.ringbuf_reserve(sizeof(*e));
    if (!e) {
        u32 key = 0;
        u64 *count = dropped_events.lookup(&key);
        if (count) {
            (*count)++;
        }
        return;
    }

    e->pid = bpf_get_current_pid_tgid() >> 32;  // for /proc/$PID
    e->uid = uid;

    if (bpf_probe_read_user_str(e->path, PATH_MAX_LEN, filename) < 0) {
        nfs_events.ringbuf_discard(e, 0);
        return;
    }

    // Relative paths: always forward to userspace as we can't know the current working
    // directory without unbound loops in BPF.
    if (e->path[0] != '/') {
        nfs_events.ringbuf_submit(e, 0);
        return;
    }

    // Match known NFS / shared mount prefixes for absolute paths
    if (starts_with(e->path, filter_mnt, 9) ||
        starts_with(e->path, filter_home, 6) ||
        starts_with(e->path, filter_data, 6) ||
        starts_with(e->path, filter_public, 8)) {

        nfs_events.ringbuf_submit(e, 0);
        return;
    }

    nfs_events.ringbuf_discard(e, 0);
}

TRACEPOINT_PROBE(syscalls, sys_enter_openat) {
    trace_nfs(args, (const char *)args->filename);
    return 0;
}

TRACEPOINT_PROBE(syscalls, sys_enter_openat2) {
    trace_nfs(args, (const char *)args->filename);
    return 0;
}
"""


@dataclasses.dataclass(frozen=True)
class Event:
    """Represents an event recorded in the BPF program."""

    pid: int
    uid: int
    path: Path


def get_parser() -> argparse.ArgumentParser:
    """Return the argument parser."""
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument(
        "config",
        help="Path to an INI configuration file with a [DEFAULT] section.",
        default="/etc/infra-tracing-nfs.ini",
        nargs="?",
    )
    return parser


@cache
def resolve_path(path: str) -> Path:
    """Resolve all symlinks in a path and cache the result."""
    return Path(path).resolve()


@cache
def resolve_uid(project: str, uid: int) -> str:
    """Get the username from the UID and cache it."""
    try:
        return pwd.getpwuid(uid).pw_name
    except KeyError:
        return f"{project}.{uid} (not found)"


@dataclasses.dataclass(frozen=True)
class StreamLabels:
    """Represent all the possible stream labels used when parsing the NFS traces.

    The instance is immutable and as such can be used as dictionary key.

    """

    user: str
    dependency: str
    dest_dir: str
    dumps_server: Optional[str] = None

    def asdict(self) -> dict[str, str]:
        """Return the dict representation of the object skipping undefined fields."""
        return {
            field.name: getattr(self, field.name)
            for field in dataclasses.fields(self)
            if getattr(self, field.name) is not None
        }


class NFSTracer:
    """Manage the NFS BPF tracing program and the push of logs to Loki."""

    def __init__(self, config: configparser.SectionProxy):
        """Initialize the instance."""
        self.loki_url = config["loki_url"]
        if not self.loki_url.endswith("/"):
            self.loki_url += "/"

        self.project = Path("/etc/wmcs-project").read_text().strip()
        if not self.project:
            raise RuntimeError("Project name in /etc/wmcs-project is empty")

        self.hostname = gethostname()
        self.in_toolforge_k8s = (
            config.getboolean("in_k8s_node", fallback=False) and self.project in TOOLFORGE_PROJECTS
        )

        self.buffer_secs = config.getfloat("buffer_secs", 30.0)
        self.buffer_lines = config.getint("buffer_lines", 300)

        self.session = Session()
        self.session.auth = (config["username"], config["password"])
        self.session.headers.update({"User-Agent": "infra-tracing NFS tracer"})

        self.streams_queue: queue.Queue[Event] = queue.Queue()
        self.suppressed_errors: Counter[str] = Counter()
        self.last_error_times: defaultdict[str, float] = defaultdict(float)

        self.bpf: Any
        self.bpf_dropped: Any

    def get_user_home(self, username: str) -> Path:
        """Resolve and cache the home path for a given username/tool name."""
        if self.in_toolforge_k8s:  # tool inside k8s
            path = f"/data/project/{username}/"
        elif self.project in TOOLFORGE_PROJECTS and username.startswith(f"{self.project}."):
            # tool user outside k8s
            username = username.split(".", 1)[1]
            path = f"/data/project/{username}/"
        else:  # normal user outside k8s
            path = f"/home/{username}/"

        return resolve_path(path)

    def get_labels(self, relative_path: Path, username: str) -> Optional[StreamLabels]:
        """Return a dict of labels to pass to loki based on path accessed."""
        parts = relative_path.parts
        if not parts or (len(parts) == 1 and parts[0] == "."):
            return None  # Root of the base_path, nothing to trace

        level1 = parts[0]
        level2 = parts[1] if len(parts) >= 2 else ""
        labels = None

        if level1.startswith("dumps"):
            labels = StreamLabels(
                user=username,
                dependency="dumps",
                dumps_server=level1,
                dest_dir=level2,
            )

        elif level1.endswith(f"{self.project}-home"):
            dest_dir = "__self__" if username == level2 else level2
            # Avoid tracking attempts to load files from non-existent homes
            if dest_dir != "__self__" and not (Path(BASE_PATH) / level1 / dest_dir).exists():
                logger.info("Skipping tracing of non-existent home dir: %s", dest_dir)
                return None

            labels = StreamLabels(
                user=username,
                dependency="users-home",
                dest_dir=dest_dir,
            )

        elif level1.endswith(f"{self.project}-project"):
            dest_dir = "__self__" if username == level2 else level2
            # Avoid tracking attempts to load files from non-existent projects
            if dest_dir != "__self__" and not (Path(BASE_PATH) / level1 / dest_dir).exists():
                logger.info("Skipping tracing of non-existent project dir: %s", dest_dir)
                return None

            labels = StreamLabels(
                user=username,
                dependency=f"{self.project}-home",
                dest_dir=dest_dir,
            )

        elif level1.endswith("scratch"):
            labels = StreamLabels(
                user=username,
                dependency="scratch",
                dest_dir=level2,
            )

        return labels

    def push_to_loki(
        self, streams: defaultdict[StreamLabels, list[tuple[str, str]]], counter: int
    ) -> bool:
        """Push to Loki the current buffered streams, returns True on success, False otherwise."""
        data: dict[str, list[dict]] = {"streams": []}
        for labels, values in streams.items():
            data["streams"].append(
                {
                    "stream": {
                        # Use service_name as Loki will automatically create one if not present
                        "service_name": "nfs",
                        "project": self.project,
                        "hostname": self.hostname,
                        "toolforge_k8s": str(self.in_toolforge_k8s).lower(),
                        **labels.asdict(),
                    },
                    "values": values,
                }
            )

        message = f"{counter} log lines across {len(streams)} streams to Loki"
        try:
            logger.debug("Sending %s", message)
            response = self.session.post(
                f"{self.loki_url}loki/api/v1/push", json=data, verify=False, timeout=15
            )
            response.raise_for_status()
            logger.info("Sent %s", message)
            return True
        except RequestException as e:
            status_code = getattr(e.response, "status_code", 999)
            logger.exception(
                "Failed to send %s at %s (sleeping for 10s): %s\n%s%s",
                message,
                self.loki_url,
                e,
                getattr(e.response, "text", None),
                # Include the data for client errors, will not be retried
                f"\n\n{pformat(data)}" if status_code < 500 else "",
            )

            if status_code < 500:
                # Tell the script to drop the data on client error (has been logged)
                return True

            time.sleep(10)  # Wait before retrying to push on server errors
            return False

    def trace(self) -> None:
        """Attach the BPF program and start the infinite loop of polling for traces."""
        self.bpf = BPF(text=BPF_PROGRAM, cflags=[f"-DSKIP_ROOT={int(self.in_toolforge_k8s)}"])
        self.bpf_dropped = self.bpf.get_table("dropped_events")
        self.bpf["nfs_events"].open_ring_buffer(self._trace_event)
        threading.Thread(target=self._parse_traces, daemon=True).start()

        logger.info(
            "Watching directory: %s, pushing to loki instance: %s", BASE_PATH, self.loki_url
        )

        try:
            while True:
                self.bpf.ring_buffer_poll(500)
        except Exception:
            logger.exception("Unexpected error")

    def _log_error(self, msg_type: str, msg: str) -> None:
        """Log a given error message type at most once every 5 seconds."""
        self.suppressed_errors[msg_type] += 1
        now = time.time()
        interval = 5  # Log at most every N seconds

        if now - self.last_error_times[msg_type] > interval:
            logger.error(
                "Error %s BPF event (suppressed %d errors in the last %ds): %s",
                msg_type,
                self.suppressed_errors[msg_type],
                interval,
                msg,
            )
            self.suppressed_errors[msg_type] = 0
            self.last_error_times[msg_type] = now

    def _trace_event(self, _context: Any, data: Any, _size: int) -> None:
        """Callback for the BPF ring buffer events, reads the event and pushes it to a queue.

        Using a Python queue to be quick and keep the interaction with BPF as short as possible.

        """
        try:
            event = self.bpf["nfs_events"].event(data)
            # Ensure to skip anything after the null terminator
            path_bytes = event.path.split(b"\x00", 1)[0]
            path = Path(path_bytes.decode("utf-8", "replace"))
            # Use a dedicated Event dataclass to avoid storing in the queue objects
            # created by bcc, better to keep them short-lived.
            self.streams_queue.put(Event(pid=event.pid, uid=event.uid, path=path))
        except Exception as e:
            self._log_error("processing", str(e))

    def _parse_traces(self) -> None:
        """Start the infinite loop of polling for trace data from the queue."""
        streams: defaultdict[StreamLabels, list[tuple[str, str]]] = defaultdict(list)
        counter = 0
        last_time = datetime.now(tz=timezone.utc)
        last_bpf_dropped = 0

        while True:
            try:
                cur_time = datetime.now(tz=timezone.utc)
                if (cur_time - last_time) > timedelta(
                    seconds=self.buffer_secs
                ) or counter > self.buffer_lines:
                    last_time = cur_time

                    # Check for kernel dropped events
                    total_bpf_dropped = self.bpf_dropped[0].value
                    new_bpf_drops = total_bpf_dropped - last_bpf_dropped
                    last_bpf_dropped = total_bpf_dropped
                    if new_bpf_drops > 0:
                        logger.warning(
                            "Kernel dropped %s events because BPF ring buffer was full!",
                            new_bpf_drops,
                        )

                    if streams:
                        if self.push_to_loki(streams, counter):
                            streams = defaultdict(list)
                            counter = 0

                try:
                    event = self.streams_queue.get(timeout=1.0)
                except queue.Empty:
                    continue

                self.streams_queue.task_done()

                if event.path.is_absolute():
                    path = event.path.resolve()  # Resolve all symlinks
                else:
                    try:
                        cwd_path = Path(f"/proc/{event.pid}/cwd")
                        path = cwd_path.resolve() / event.path
                    except (OSError, RuntimeError):
                        continue

                if not path.is_relative_to(BASE_PATH):
                    continue

                username = resolve_uid(self.project, event.uid)
                if self.in_toolforge_k8s:
                    if not username.startswith(f"{self.project}."):
                        continue  # Skip non-tools activity in the k8s hosts

                    # Remove the $project. prefix from the usernames to make the data more readable.
                    username = username.split(".", 1)[1]

                labels = self.get_labels(path.relative_to(BASE_PATH), username)
                if labels is None:
                    continue

                # Skip any activity in the tool/user's own home directory
                user_home = self.get_user_home(labels.user)
                if path.is_relative_to(user_home):
                    continue

                log_entry = (str(time.time_ns()), f"PID={event.pid} UID={event.uid} PATH={path}")
                streams[labels].append(log_entry)
                counter += 1
                if logger.isEnabledFor(logging.DEBUG):
                    logger.debug([labels, log_entry])

            except Exception as e:
                self._log_error("parsing", str(e))


def main() -> None:
    """Run the program."""
    urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
    args = get_parser().parse_args()
    config_parser = configparser.ConfigParser(
        defaults={
            "loki_url": "https://localhost:30004/",
            "buffer_secs": "30.0",
            "buffer_lines": "300",
            "log_level": "INFO",
            "in_k8s_node": "false",
        },
    )
    config_parser.read(args.config)
    config = config_parser["nfs"]
    logging.basicConfig(
        level=getattr(logging, config["log_level"].upper()),
        format="%(asctime)s %(levelname)s: %(message)s",
    )

    tracer = NFSTracer(config)
    tracer.trace()


if __name__ == "__main__":
    main()
