#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 Chris Danis & Wikimedia Foundation, Inc.
"""Import encrypted fundraising data files into MediaWiki via mwscript-k8s.

This wrapper scans /var/lib/fundraising-data-uploader for files matching *.ready
(or some other pattern that indicates the sender has finished writing
 to a temporary file, and atomically moved the full content into place).

Then, starting with the oldest file, we decrypt it using a separately-provided
age-format identity file, launch the maintenance script via mwscript-k8s,
and copy the decrypted input into the container via kubectl cp + atomic mv.
The maintenance script polls for the input file before proceeding.

This avoids storing decrypted donor data as a ConfigMap -- it never enters
the k8s API server at all.

On success the input file is removed.  On failure the script exits non-zero,
so the systemd unit is marked failed and monitoring can fire.

Repeat this for all files until error, or no more files ready to process.

Primary deployment server gating is handled at the Puppet level via the
$deployment_server hiera key (not WMFMasterDatacenter), so this script only
runs on the active deployment server. See:
https://wikitech.wikimedia.org/wiki/Switch_Datacenter/DeploymentServer
"""
import argparse
import hashlib
import json
import logging
import subprocess
import sys
from pathlib import Path
import tempfile

UPLOAD_DIR = Path("/var/lib/fundraising-data-uploader")
FILE_GLOB = "*.ready"
# Reject input files larger than 2 GiB to keep k8s Job payload bounded.
MAX_INPUT_SIZE = 2 * 1024 * 1024 * 1024  # 2 GiB

logger = logging.getLogger(__name__)


def _kubectl(
    kubeconfig: str, args: list[str], check: bool = True,
) -> subprocess.CompletedProcess[str]:
    """Run kubectl with the given kubeconfig."""
    cmd = ["/usr/local/bin/kubectl", "--kubeconfig", kubeconfig] + args
    return subprocess.run(cmd, capture_output=True, text=True, check=check)


def process_file(
    path: Path, identity_file: Path, mwscript_args: list[str], tmpdir: Path
) -> None:
    """Decrypt path to a temp file and copy it into the k8s container."""
    logger.info("Processing %s", path)

    # Guard against oversized input files.
    # TODO: chunk up larger inputs if needed
    if path.stat().st_size > MAX_INPUT_SIZE:
        raise RuntimeError(
            f"{path} is {path.stat().st_size} bytes; "
            f"exceeds {MAX_INPUT_SIZE}-byte limit"
        )

    # Decrypt to a temp file. The tempfile module cleans up on exit.
    decrypted = tmpdir / f"{path.stem}.decrypted"
    age_cmd = [
        "/usr/bin/age",
        "--decrypt",
        "--identity",
        str(identity_file),
        "-o",
        str(decrypted),
        str(path),
    ]
    result = subprocess.run(age_cmd, check=False)
    if result.returncode != 0:
        raise RuntimeError(f"age exited {result.returncode} while decrypting {path}")

    # Launch the job WITHOUT --file so no ConfigMap is created with decrypted data.
    # The maintenance script is expected to poll for its input file before processing.
    remote_path = f"/tmp/{decrypted.name}"
    mwscript_cmd = (
        ["/usr/local/bin/mwscript-k8s", "-o", "json", "--timeout", "2h"]
        + mwscript_args
        + [remote_path]
    )

    result = subprocess.run(mwscript_cmd, check=False, capture_output=True, text=True)
    if result.returncode != 0:
        logger.error("mwscript-k8s stderr: %s", result.stderr.strip())
        logger.error("mwscript-k8s stdout: %s", result.stdout.strip())
        raise RuntimeError(
            f"mwscript-k8s exited {result.returncode} while processing {path}"
        )

    status = json.loads(result.stdout)
    mscript = status["mwscript"]
    job_name = mscript["job"]
    container_name = status["mediawiki_container"]
    namespace = mscript["namespace"]
    kubeconfig = mscript["config"]

    # Wait for the pod to be in Ready state so we can kubectl cp into it.
    logger.info("Waiting for pod of job %s to become ready...", job_name)
    wait_result = _kubectl(
        kubeconfig,
        [
            "-n", namespace,
            "wait", f"job/{job_name}",
            "--for=condition=ready",
            "--timeout=120s",
        ],
        check=False,
    )
    if wait_result.returncode != 0:
        raise RuntimeError(
            f"kubectl wait pod ready failed: {wait_result.stderr.strip()}"
        )

    # Copy decrypted file to a temp location in the container first, then atomically
    # rename it to the final path. The maintenance script polls for the final path
    # and won't see a partial file.
    tmp_prefix = hashlib.md5(path.name.encode()).hexdigest()[:12]
    remote_tmp = f"/tmp/fundraising.{tmp_prefix}"

    logger.info("Copying decrypted data to container...")
    cp_result = _kubectl(
        kubeconfig,
        [
            "-n", namespace, "cp",
            str(decrypted),
            f"job/{job_name}:{remote_tmp}",
            "--container", container_name,
        ],
        check=False,
    )
    if cp_result.returncode != 0:
        raise RuntimeError(
            f"kubectl cp failed (rc={cp_result.returncode}): "
            f"{cp_result.stderr.strip()}"
        )

    logger.info("Moving file into place in container...")
    mv_result = _kubectl(
        kubeconfig,
        [
            "-n", namespace, "exec",
            f"job/{job_name}",
            "--container", container_name,
            "--", "/bin/mv", remote_tmp, remote_path,
        ],
        check=False,
    )
    if mv_result.returncode != 0:
        raise RuntimeError(
            f"kubectl exec mv failed (rc={mv_result.returncode}): "
            f"{mv_result.stderr.strip()}"
        )

    # Wait for the maintenance script job to complete.
    job_ref = f'job/{job_name}'
    kubectl_wait_job_cmd = [
        "/usr/local/bin/kubectl-wait-job",
        "--kubeconfig",
        kubeconfig,
        "-n",
        namespace,
        job_ref,
    ]

    # kubectl-wait-job exits 0 (complete), 1 (failed), or 3 (transient error).
    # Retry transient errors with a bounded attempt count to avoid silently
    # busy-looping if something is permanently broken.
    max_attempts = 20
    for attempt in range(1, max_attempts + 1):
        logger.info(
            "Waiting for %s to finish (attempt %d/%d)...",
            job_ref,
            attempt,
            max_attempts,
        )
        result = subprocess.run(kubectl_wait_job_cmd, check=False)
        if result.returncode == 0:
            break  # job completed successfully
        if result.returncode == 1:
            raise RuntimeError(f"{job_ref} failed")
        # rc == 3: transient k8s API error; retry
        if attempt == max_attempts:
            raise RuntimeError(
                f"kubectl-wait-job still could not determine status of {job_ref} "
                f"after {max_attempts} attempts"
            )

    path.unlink()
    logger.info("Success! Removed %s", path)


def main() -> int:
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s %(levelname)s %(message)s",
    )

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--script",
        required=True,
        help="MediaWiki maintenance script name (passed to mwscript-k8s)",
    )
    parser.add_argument(
        "--wiki",
        required=True,
        help="Wiki database name (e.g. metawiki)",
    )
    parser.add_argument(
        "--identity-file",
        required=True,
        type=Path,
        help="Path to the age symmetric identity file used for decryption",
    )
    parser.add_argument(
        "--extra-script-args",
        action="append",
        default=[],
        help="Additional args passed to the maintenance script (repeatable)",
    )
    args = parser.parse_args()

    candidates = sorted(UPLOAD_DIR.glob(FILE_GLOB), key=lambda p: p.stat().st_mtime)
    if not candidates:
        return 0

    with tempfile.TemporaryDirectory(prefix="fundraising-data-import-") as tmpdir:
        mwscript_args = [
            "--",
            args.script,
            f"--wiki={args.wiki}",
        ] + args.extra_script_args

        for path in candidates:
            try:
                process_file(path, args.identity_file, mwscript_args, Path(tmpdir))
            except Exception as exc:  # noqa: BLE001
                logger.error("%s", exc)
                return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
