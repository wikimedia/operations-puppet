#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0

"""
Detects a stale (ESTALE) NFS mountpoint and forces a lazy unmount so that
a systemd automount (or autofs) unit can transparently remount it on next
access.

Modes:
  - one-shot:  check once and exit (suitable for a systemd.timer OnCalendar/
               OnUnitActiveSec trigger driving a oneshot service)
  - periodic:  loop forever, checking every N seconds (suitable for running
               directly as a long-lived systemd service)

Exit codes (one-shot mode):
  0 - mount OK
  1 - mount was stale, umount -l issued successfully
  2 - mount was stale, umount -l failed
  3 - unexpected error checking the mount
"""

import argparse
import errno
import logging
import os
import subprocess
import sys
import time


def check_and_recover(mountpoint: str, umount_cmd: list[str], log: logging.Logger) -> int:
    """
    Check a single mountpoint for ESTALE and lazy-unmount it if stale.

    Returns an exit-code-style int (see module docstring) rather than raising,
    so callers in both one-shot and periodic mode can handle it uniformly.
    """
    try:
        os.stat(mountpoint)
        log.debug("mount OK: %s", mountpoint)
        return 0
    except OSError as e:
        if e.errno == errno.ESTALE:
            log.warning("ESTALE detected on %s, forcing lazy unmount", mountpoint)
            try:
                subprocess.run(umount_cmd, check=True, capture_output=True, text=True)
                log.info(
                    "umount -l succeeded for %s; automount will remount on next access",
                    mountpoint,
                )
                return 1
            except subprocess.CalledProcessError as umount_err:
                log.error(
                    "umount -l failed for %s (rc=%d): %s",
                    mountpoint,
                    umount_err.returncode,
                    umount_err.stderr.strip() if umount_err.stderr else umount_err,
                )
                return 2
        else:
            # Any other error (ENOTCONN, ETIMEDOUT, EIO, etc.) - log it but
            # don't blindly umount, since ESTALE is the only condition we
            # know is safely resolved by remounting. Other errors may be
            # transient network issues that soft/timeo/retrans already handle.
            log.error("unexpected error stat()ing %s: %s", mountpoint, e)
            return 3


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Detect ESTALE on an NFS mountpoint and lazy-unmount as needed."
    )
    parser.add_argument(
        "mountpoint",
        help="Path to the NFS mountpoint to check (e.g. /mnt/nfs/dumps-dumps-nfs.wikimedia.org)",
    )
    parser.add_argument(
        "--mode",
        choices=["one-shot", "periodic"],
        default="one-shot",
        help="Run once and exit, or check every --interval seconds (default: one-shot)",
    )
    parser.add_argument(
        "--interval",
        type=float,
        default=15.0,
        help="Seconds between checks in periodic mode (default: 15)",
    )
    parser.add_argument(
        "--verbose",
        "-v",
        action="store_true",
        help="Enable debug logging (logs every successful check, not just failures)",
    )
    args = parser.parse_args()

    log_format = "%(asctime)s %(levelname)s dumps-nfs-client-sitter: %(message)s"
    if not sys.stdout.isatty():
        log_format = "%(levelname)s %(message)s"
    logging.basicConfig(
        level=logging.DEBUG if args.verbose else logging.INFO,
        format=log_format,
    )
    log = logging.getLogger("dumps-nfs-client-sitter")

    umount_cmd = ["umount", "-l", args.mountpoint]

    if args.mode == "one-shot":
        return check_and_recover(args.mountpoint, umount_cmd, log)

    # periodic mode: loop forever, never exit on a single failed check
    log.info(
        "starting periodic ESTALE check on %s every %.1fs",
        args.mountpoint,
        args.interval,
    )
    try:
        while True:
            check_and_recover(args.mountpoint, umount_cmd, log)
            time.sleep(args.interval)
    except KeyboardInterrupt:
        log.info("interrupted, exiting")
        return 0


if __name__ == "__main__":
    sys.exit(main())
