#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0

import shlex
import subprocess
import time
import logging

from typing import Any, Optional, Type, Set

SSH_CONNECT_TIMEOUT_SECONDS = 6
HOSTS_ACCESS_TIMEOUT_MINUTES = 5

log = logging.getLogger()


def ssh_bash(fqdn, cmd, *args, **kwargs) -> subprocess.CompletedProcess[str]:
    ssh_cmd = [
        "ssh",
        "-o",
        "BatchMode=yes",
        "-o",
        f"ConnectTimeout={SSH_CONNECT_TIMEOUT_SECONDS}",
    ]
    return subprocess.run(
        ssh_cmd + [fqdn, "bash", "-c", shlex.quote(cmd)], *args, **kwargs
    )


def user_confirmation(prompt: str, prompt_type: Type) -> Optional[Any]:
    answer = None
    while answer is None:
        try:
            answer = prompt_type(input(prompt))
        except ValueError:
            answer = None
    return answer


def wait_hosts_access(hosts: Set[str]) -> bool:
    def proc_for_host(host):
        return subprocess.Popen(
            [
                "ssh",
                "-o",
                "UserKnownHostsFile=/dev/null",
                "-o",
                "StrictHostKeyChecking=no",
                "-o",
                "BatchMode=yes",
                "-o",
                f"ConnectTimeout={SSH_CONNECT_TIMEOUT_SECONDS}",
                host,
                "sudo id",
            ],
        )

    procs = {h: proc_for_host(h) for h in hosts}

    deadline = time.time() + 60 * HOSTS_ACCESS_TIMEOUT_MINUTES
    while time.time() < deadline:
        done = []
        for host, proc in procs.items():
            status = proc.poll()
            if status is None:
                continue
            if status == 0:
                done.append(host)
            else:
                procs[host] = proc_for_host(host)
        for host in done:
            del procs[host]

        if len(procs) == 0:
            return True

        log.info(f"Awaiting access for: {','.join(list(procs.keys()))}")
        time.sleep(15)

    log.warning(f"Hosts not accessible past deadline: {list(procs.keys())!r}")
    return False


def wait_subprocesses(proc_gen, timeout=None):
    """Waits for subprocesses to complete within a given timeout.

    Args:
        proc_gen: Generator yielding (command, subprocess.Popen) instances.
        timeout: Maximum time (in seconds) to wait before terminating processes.

    Returns:
        A list of tuples (command, return_code, stdout, stderr).
    """
    processes = {proc: cmd for cmd, proc in proc_gen}
    start_time = time.time()

    results = {}

    while processes:
        for proc in list(processes.keys()):
            if proc.poll() is not None:  # Process has finished
                stdout, stderr = proc.communicate()
                results[processes[proc]] = (
                    proc.returncode,
                    stdout.decode(),
                    stderr.decode(),
                )
                del processes[proc]

        if timeout and (time.time() - start_time) >= timeout:
            for proc in processes.keys():
                proc.terminate()
            time.sleep(1)  # Give them a moment to exit
            for proc in processes.keys():
                if proc.poll() is None:  # If still running, force kill
                    proc.kill()
            log.warning("Timeout reached! Terminated remaining processes.")

            # Capture remaining terminated process results
            for proc in list(processes.keys()):
                stdout, stderr = proc.communicate()
                results[processes[proc]] = (
                    proc.returncode,
                    stdout.decode(),
                    stderr.decode(),
                )
                del processes[proc]

            break

        time.sleep(2)  # Prevents busy-waiting

    return results


def as_table(headers, data, separator="|"):
    res = []
    # Format data in columns
    column_widths = [max(len(str(item)) for item in col) for col in zip(headers, *data)]
    res.append(
        separator.join(
            f"{header.ljust(width)}" for header, width in zip(headers, column_widths)
        )
    )
    res.append(separator.join("-" * width for width in column_widths))
    for row in data:
        res.append(
            separator.join(
                f"{str(item).ljust(width)}" for item, width in zip(row, column_widths)
            )
        )

    return res
