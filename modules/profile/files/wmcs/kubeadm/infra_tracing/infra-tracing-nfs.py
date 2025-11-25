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
    buffer_lines = 100
    # Name of the level in the Python's logging module to use
    log_level = INFO

"""
import argparse
import configparser
import logging
import pwd
from datetime import datetime, timedelta, timezone
from functools import cache
from pathlib import Path
from time import sleep, time_ns
from typing import Any

import urllib3
from bcc import BPF  # type: ignore[import-not-found]  # not available in PyPI
from requests import Session
from requests.exceptions import RequestException

logger = logging.getLogger(__name__)


BASE_PATH = "/mnt/nfs"
BPF_PROGRAM = """
#include <uapi/linux/ptrace.h>

int check_if_fname(struct pt_regs *ctx) {
    char fname[256];
    bpf_probe_read_user(&fname, sizeof(fname), (void *)PT_REGS_PARM2(ctx));
    int uid = bpf_get_current_uid_gid();

    // trying to optimize the amount of instructions :/
    // char by char hardcoded check, as loops are costly in ebpf
    if (
        uid == 0 // skip root
        || fname[0] == '/' && ( // it's a full path
            fname[1] != 'm' // but not /mnt/nfs/
            || fname[2] != 'n'
            || fname[3] != 't'
            || fname[4] != '/'
            || fname[5] != 'n'
            || fname[6] != 'f'
            || fname[7] != 's'
        )
    )
        return 0;

    bpf_trace_printk("%s@@@%d", fname, uid);
    return 0;
}
"""


def resolve_path(pid: int, relative_path: Path) -> Path:
    """Try to return the absolute path based on the process working directory."""
    try:
        cwd_path = Path(f"/proc/{pid}/cwd")
        return cwd_path.resolve() / relative_path
    except (OSError, RuntimeError):
        return relative_path


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
def resolve_uid(project: str, uid: int) -> str:
    """Get the username from the UID and cache it."""
    try:
        return pwd.getpwuid(uid).pw_name
    except KeyError:
        return f"{project}.{uid} (not found)"


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

        self.buffer_secs = config.getfloat("buffer_secs", 30.0)
        self.buffer_lines = config.getint("buffer_lines", 100)

        self.session = Session()
        self.session.auth = (config["username"], config["password"])
        self.session.headers.update({"User-Agent": "infra-tracing NFS tracer"})

        self.bpf = BPF(text=BPF_PROGRAM)

    def get_labels(self, relative_path: Path, tool_name: str) -> dict[str, Any]:
        """Return a dict of labels to pass to loki based on path accessed."""
        parts = relative_path.parts
        if not parts or (len(parts) == 1 and parts[0] == "."):
            return {}  # Root of the base_path, nothing to trace

        level1 = parts[0]
        level2 = parts[1] if len(parts) >= 2 else ""
        labels = {}

        if level1.startswith("dumps"):
            labels = {
                "dependency": "dumps",
                "dumps_server": parts[0],
                "dumps_path": level2,
            }

        elif level1.endswith(f"{self.project}-home"):
            labels = {
                "dependency": "users-home",
                "dest_user": level2,
            }

        elif level1.endswith(f"{self.project}-project"):
            dest_tool = f"{self.project}.{level2}" if level2 else ""
            if dest_tool == tool_name:
                dest_tool = "self"

            labels = {
                "dependency": f"{self.project}-home",
                "dest_tool": dest_tool,
            }

        elif level1.endswith("scratch"):
            labels = {
                "dependency": "scratch",
            }

        return labels

    def push_to_loki(self, entries: list[tuple[str, str, dict]]) -> bool:
        """Push to Loki the current buffered log entries, returns True on success."""
        data = {
            "streams": [
                {
                    "stream": {
                        "app": "nfs",
                        "project": self.project,
                    },
                    "values": entries,
                },
            ],
        }
        try:
            logger.debug("Sending %d log lines to Loki", len(entries))
            response = self.session.post(
                f"{self.loki_url}loki/api/v1/push", json=data, verify=False, timeout=15
            )
            response.raise_for_status()
            logger.info("Sent %d log lines to Loki", len(entries))
            return True
        except RequestException as e:
            logger.exception(
                "Failed to send %d log lines to %s (sleeping for 10s): %s",
                len(entries),
                self.loki_url,
                e,
            )
            sleep(10)  # Wait before retrying to push if there are enough lines
            return False

    def trace(self) -> None:
        """Attach the BPF program and start the infinite loop of polling for traces."""
        self.bpf.attach_kprobe(event="do_sys_openat2", fn_name="check_if_fname")
        self.bpf.attach_kprobe(event="do_sys_open", fn_name="check_if_fname")
        logger.info(
            "Watching directory: %s, pushing to loki instance: %s", BASE_PATH, self.loki_url
        )

        try:
            self._trace()
        except Exception:
            logger.exception("Unexpected error")

    def _trace(self) -> None:
        """Start the infite loop of polling for traces."""
        logs: list[tuple[str, str, dict]] = []
        last_time = datetime.now(tz=timezone.utc)
        while True:
            cur_time = datetime.now(tz=timezone.utc)
            if (cur_time - last_time) > timedelta(seconds=self.buffer_secs) or len(
                logs
            ) > self.buffer_lines:
                last_time = cur_time
                if logs:
                    if self.push_to_loki(logs):
                        logs = []

            (_task, pid, _cpu, _flags, _ts, msg) = self.bpf.trace_fields()
            raw_path, raw_uid = msg.decode().split("@@@", 1)
            # logger.debug([raw_path, raw_uid])
            path = Path(raw_path)

            if not path.is_absolute():
                path = resolve_path(pid, path)

            # logger.debug([path, path.is_relative_to(BASE_PATH), raw_uid])
            if not path.is_relative_to(BASE_PATH):
                continue

            username = resolve_uid(self.project, int(raw_uid))
            # logger.debug([username, raw_uid])
            if not username.startswith(f"{self.project}."):
                continue

            labels = self.get_labels(path.relative_to(BASE_PATH), username)
            # logger.debug([labels, raw_uid])
            if not labels:
                continue

            labels["tool"] = username
            log_entry = (str(time_ns()), f"PID={pid} UID={raw_uid} PATH={path}", labels)
            logs.append(log_entry)
            logger.debug(log_entry)


def main() -> None:
    """Run the program."""
    urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
    args = get_parser().parse_args()
    config_parser = configparser.ConfigParser(
        defaults={
            "loki_url": "https://localhost:30004/",
            "buffer_secs": "30.0",
            "buffer_lines": "100",
            "log_level": "INFO",
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
