#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0

import argparse
import base64
import logging
import os
import re
import requests
import subprocess

from pathlib import Path

import toml

log = logging.getLogger(__name__)

DC = ("eqiad", "codfw", "esams", "ulsfo", "eqsin", "drmrs", "magru")
PATH_RE = re.compile(
    "^(/etc/haproxy/|/etc/haproxy/ipblocks.d/|/etc/confd/.*_etc_haproxy.*|/usr/share/haproxy)"
)
COMPILER_RE = re.compile(
    ".*(https://puppet-compiler.wmflabs.org/output/[0-9]+/[0-9]+/)"
)
TIMEOUT = 30
USER_AGENT = 'HaproxyTest/0.1 (sre-traffic@wikimedia.org)'

CWD = os.path.dirname(__file__)
PARENT_DIR = os.path.abspath(os.path.join(CWD, os.pardir))


def get_pcc_url(hostname, patch_id, pcc):
    cmd = " ".join((pcc, "-N", patch_id, hostname))
    log.debug("PCC cmd: %s", cmd)
    for line in os.popen(cmd).readlines():
        match = COMPILER_RE.match(line)
        if match:
            group = match.group(1)
            log.debug("PCC URL: %s", group)
            return group

    log.error("Issues with get_pcc_url()")
    raise Exception("Issues with get_pcc_url()")


def dump_files(url, hostname):
    catalog_url = "{}/{}/change.{}.pson.gz".format(url, hostname, hostname)
    log.debug("Catalog URL: %s", catalog_url)

    catalog = requests.get(catalog_url, timeout=TIMEOUT, headers={'user-agent': USER_AGENT}).json()
    for resource in catalog["resources"]:
        if resource["type"] != "File":
            continue
        if PATH_RE.match(resource["title"]) is None:
            continue
        if "content" not in resource["parameters"]:
            continue
        path = os.path.join(PARENT_DIR, resource["title"].lstrip("/"))
        log.debug("Creating %s", path)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "wb") as f:
            content = resource["parameters"]["content"]
            if isinstance(content, str):
                f.write(resource["parameters"]["content"].encode("utf-8"))
            elif isinstance(content, dict):
                if "__ptype" in content and content["__ptype"] == "Binary":
                    f.write(base64.b64decode(content["__pvalue"]))
                else:
                    log.error("Implement support to serialize %s", content)
                    raise NotImplementedError("implement support to serialize %s", content)
            else:
                log.error("Implement support for type %s", type(content))
                raise NotImplementedError("Implement support for type %s", type(content))


def run_confd():
    """Run confd to generate the files."""
    confd_output_files = []
    # TODO: convert all the file to use Path.
    parent = Path(PARENT_DIR)
    config_path = parent / "etc/confd/conf.d"
    for config_file in config_path.iterdir():
        # Parse the file as toml
        log.debug("Parsing config file %s", config_file)
        config = toml.loads(config_file.read_text())
        try:
            destination = config["template"]["dest"].replace(
                "/etc/haproxy", str(parent / "etc/haproxy")
            )
            confd_output_files.append(Path(destination))
            config["template"]["dest"] = destination

            # Patch the paths.
            config_file.write_text(toml.dumps(config))
        except KeyError:
            log.error("File %s doesn't contain a valid dest entry", config_file)
    # Now run confd.
    confd_cmd = [
            "/usr/bin/confd",
            # "-log-level","DEBUG",
            "-confdir",
            str(parent / "etc/confd"),
            "-backend",
            "file",
            "-file",
            str(parent / "etc/confd/confd_stub_data.yaml"),
            "-onetime",
    ]
    log.info("Running confd command: %s", confd_cmd)
    subprocess.run(confd_cmd, check=True)

    for output in confd_output_files:
        log.debug("Content of %s\n\n%s\n\n", output.name, output.read_text())


def main(hostname, patch_or_url, pcc):
    if patch_or_url.startswith("https://"):
        pcc_url = patch_or_url
    else:
        patch_id = patch_or_url
        log.info("Running PCC for change %s...", patch_id)
        pcc_url = get_pcc_url(hostname, patch_id, pcc)
    log.debug("PCC URL: %s", pcc_url)

    log.info("Dumping PCC files from %s", hostname)
    dump_files(pcc_url, hostname)

    parent = Path(PARENT_DIR)

    haproxy_cfg_file = Path(parent / 'etc/haproxy/haproxy.cfg')
    haproxy_cfg_content = haproxy_cfg_file.read_text()
    log.info("Commenting unused entries in haproxy.cfg")
    haproxy_cfg_content = haproxy_cfg_content.replace('set-dumpable', '# set-dumpable')
    haproxy_cfg_content = re.sub(r'(ssl-dh-param-file.*)',
                                 r'#\1',
                                 haproxy_cfg_content,
                                 flags=re.MULTILINE)
    haproxy_cfg_file.write_text(haproxy_cfg_content)

    log.info("Running confd...")
    run_confd()

    tls_cfg_file = Path(parent / 'etc/haproxy/conf.d/tls.cfg')
    log.info("Edit haproxy conffile permissions")
    tls_cfg_file.chmod(0o600)
    tls_cfg_content = tls_cfg_file.read_text()
    log.info("Replacing certificate list path")
    tls_cfg_content = tls_cfg_content.replace('/etc/haproxy/crt-list.cfg',
                                              '/run/haproxy/crt-list.cfg')

    log.debug("Configuration is now\n%s\n\n", tls_cfg_content)
    tls_cfg_file.write_text(tls_cfg_content)

    check_cmd = [
            "/usr/sbin/haproxy",
            "-V",
            "-c",
            "-f", str(parent / "etc/haproxy/haproxy.cfg"),
            "-f", str(parent / "etc/haproxy/conf.d"),
    ]
    log.info("Test haproxy executable")
    log.info("Check cmd: {}".format(" ".join(check_cmd)))
    try:
        subprocess.run(check_cmd,
                       capture_output=True,
                       text=True,
                       timeout=5,
                       check=True)
        log.info("Success!")
    except subprocess.CalledProcessError as e:
        log.error("Error while running haproxy check cmd %s", e.cmd)
        log.error("Run this script with log_level=DEBUG to see configuration file(s) content")
        log.error("Haproxy check stdout:\n\n%s\n\n", e.stdout)
        log.error("Haproxy check stderr:\n\n%s\n\n", e.stderr)
    except subprocess.TimeoutExpired:
        log.error("Timeout expired while running check command")
        raise
    except Exception as e:
        log.error("Unexpected error while running check command: %s", e)
        raise
    # Eventual other checks/tests can be described here

    log.info("If you want to re-run without recompiling pcc, run as follows:")
    log.info("python3 run.py %s %s", hostname, pcc_url)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Run haproxy configuration verification")
    parser.add_argument("--log-level", "-l",
                        choices=['DEBUG', 'INFO', 'WARNING', 'ERROR'],
                        default='INFO', help="Log level (default: INFO)")
    parser.add_argument("hostname", help="Hostname to fetch PCC data")
    parser.add_argument("patch", help="Patch or PCC url")
    parser.add_argument("--pcc",
                        default="../../../../utils/pcc",
                        required=False,
                        help="pcc executable")
    args = parser.parse_args()

    log_level = getattr(logging, args.log_level.upper())
    logging.basicConfig(
        level=log_level,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    )
    log = logging.getLogger(__name__)

    main(hostname=args.hostname,
         patch_or_url=args.patch,
         pcc=args.pcc)
