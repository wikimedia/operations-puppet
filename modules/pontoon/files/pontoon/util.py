#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0

import logging
import time

log = logging.getLogger()


# XXX this should be generalized to have proc_gen yield subprocess.Popen
# *arguments* instead then wait_hosts_access can be folded into it. We need to
# wait for long-running processes as well as keep running processes until they
# succeed (both within a timeout)
def wait_subprocesses(proc_gen, timeout=None) -> dict[str, tuple[int, str, str]]:
    """Waits for subprocesses to complete within a given timeout.

    Args:
        proc_gen: Generator yielding (command, subprocess.Popen) instances.
        timeout: Maximum time (in seconds) to wait before terminating processes.

    Returns:
        A dict of command: (return_code, stdout, stderr).
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


def as_table(headers, data, separator="|") -> list[str]:
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
