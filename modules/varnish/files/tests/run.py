#!/usr/bin/env python3

import base64
import os
import re
import sys
import tempfile

import requests
import subprocess

from pathlib import Path
from shutil import copyfile
from urllib.parse import urlparse

import toml

DC = ("eqiad", "codfw", "esams", "ulsfo", "eqsin", "drmrs", "magru")
CLUSTERS = ("text", "upload")
PATH_RE = re.compile("^(/etc/varnish/|/usr/share/varnish/|/etc/confd/.*_etc_varnish.*)")
COMPILER_RE = re.compile(
    ".*(https://puppet-compiler.wmflabs.org/output/[0-9]+/[0-9]+/)"
)
TIMEOUT = 30
USER_AGENT = 'VarnishTest/0.1 (sre-traffic@wikimedia.org)'

CC_COMMAND = (
    "exec gcc -std=gnu99 -g -O2 -fstack-protector-strong -Wformat "
    "-Werror=format-security -Wall -pthread -fpic -shared -Wl,-x "
    "-o %o %s -lmaxminddb -lsodium"
)

CWD = os.path.dirname(__file__)

PARENT_DIR = os.path.abspath(os.path.join(CWD, os.pardir))


def find_cluster(hostname):
    # eg: cp4021.ulsfo.wmnet -> DC[3] -> 'ulsfo'
    idx = int(hostname[2]) - 1
    dc = DC[idx]

    base = "https://config-master.wikimedia.org"
    for cluster in CLUSTERS:
        url = "{}/pybal/{}/{}".format(base, dc, cluster)
        r = requests.get(url, timeout=TIMEOUT, headers={'user-agent': USER_AGENT})
        if hostname in r.text:
            return cluster

    raise Exception("Unknown cluster for {}".format(hostname))


def get_pcc_url(hostname, change_num, pcc_path):
    cmd = " ".join((pcc_path, "-N", change_num, hostname))
    for line in os.popen(cmd).readlines():
        match = COMPILER_RE.match(line)
        if match:
            return match.group(1)

    raise Exception("Issues with get_pcc_url()")


def dump_files(url, hostname):
    catalog_url = "{}/{}/change.{}.pson.gz".format(url, hostname, hostname)
    print("\tCatalog URL: {}".format(catalog_url))

    resp = requests.get(catalog_url, timeout=TIMEOUT)
    if not resp.ok:
        if resp.status_code == 404:
            raise ValueError(f"Could not find the catalog at '{catalog_url}'. "
                             f"Are you sure '{hostname}' is correct?")
        elif resp.status_code >= 500:
            raise ValueError(f"PCC ERROR: Got status '{resp.status_code}' for {catalog_url}")
        else:
            raise ValueError(f"Got code '{resp.status_code} for '{catalog_url}'")

    catalog = resp.json()
    for resource in catalog["resources"]:
        if resource["type"] != "File":
            continue
        if PATH_RE.match(resource["title"]) is None:
            continue
        if resource["parameters"].get("ensure", "present") == "absent":
            continue
        if "content" in resource["parameters"]:
            _copy_templated(resource)
        if "source" in resource["parameters"]:
            src = resource["parameters"]["source"]
            if "volatile" not in src:
                continue
            _copy_stub(resource)


def _copy_templated(resource):
    path = os.path.join(PARENT_DIR, resource["title"].lstrip("/"))
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as f:
        print("\tCreating {}".format(path))
        content = resource["parameters"]["content"]
        if isinstance(content, str):
            f.write(resource["parameters"]["content"].encode("utf-8"))
        elif isinstance(content, dict):
            if "__ptype" in content and content["__ptype"] == "Binary":
                f.write(base64.b64decode(content["__pvalue"]))
            else:
                raise NotImplementedError(f"implement support to serialize {content}")
        else:
            raise NotImplementedError(f"implement support for type {type(content)}")


def _copy_stub(resource):
    parent = Path(PARENT_DIR)
    parsed = urlparse(resource["parameters"]["source"])
    origin = parent / "stubs" / Path(parsed.path).name
    dst = parent / resource["title"].lstrip("/")
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    print(f"\tCopying stub file {origin} to {dst}")
    copyfile(origin, dst)


def run_confd():
    """Run confd to generate the files."""
    confd_output_files = []
    # TODO: convert all the file to use Path.
    parent = Path(PARENT_DIR)
    config_path = parent / "etc/confd/conf.d"
    for config_file in config_path.iterdir():
        # Remove the directors configuration, we don't need it.
        if config_file.match("*varnish_directors*.vcl.toml"):
            config_file.unlink()
        else:
            # Parse the file as toml
            config = toml.loads(config_file.read_text())
            try:
                destination = config["template"]["dest"].replace(
                    "/etc/varnish", str(parent / "etc/varnish")
                )
                confd_output_files.append(Path(destination))
                config["template"]["dest"] = destination

                # Patch the paths.
                config_file.write_text(toml.dumps(config))
            except KeyError:
                print(f"ERROR: file {config_file} doesn't contain a valid dest entry.")
    # Now run confd.
    subprocess.run(
        [
            "/usr/bin/confd",
            "-confdir",
            str(parent / "etc/confd"),
            "-backend",
            "file",
            "-file",
            str(parent / "confd_stub_data.yaml"),
            "-onetime",
        ],
        check=True,
    )
    for output in confd_output_files:
        print(f"== Content of {output.name}:")
        print("")
        print(output.read_text())
        print("")
        print("=" * 30)
        print("")


def main(hostname, change_num_or_pcc_url, pcc_path, vtc_file_glob):
    if change_num_or_pcc_url.startswith("https://"):
        pcc_url = change_num_or_pcc_url
    else:
        change_num = change_num_or_pcc_url
        print("[*] running PCC for change {}...".format(change_num))
        pcc_url = get_pcc_url(hostname, change_num, pcc_path)
    print("\tPCC URL: {}\n".format(pcc_url))

    print("[*] Dumping files...")
    dump_files(pcc_url, hostname)
    print()

    print("[*] Running confd...")
    run_confd()

    print("[*] Finding cluster...")
    cluster = find_cluster(hostname)
    print("\t{} is a cache_{} host\n".format(hostname, cluster))

    print("[*] Running varnishtest (this might take a while)...")
    vcl_path = "{}/usr/share/varnish/tests:{}/etc/varnish".format(
        PARENT_DIR, PARENT_DIR
    )
    cluster_vtc_path = os.path.join(CWD, cluster)
    vtc_file_glob = os.path.basename(vtc_file_glob)
    vtc_file_glob = vtc_file_glob.split('.', maxsplit=1)[0]
    cmd = "{} -Dcc_command='{}' -Dbasepath={} -Dvcl_path={} {}/{}*.vtc".format(
        "sudo varnishtest -k", CC_COMMAND, PARENT_DIR, vcl_path, cluster_vtc_path, vtc_file_glob
    )
    print("\t{}\n".format(cmd))

    if os.getenv('VARNISHTEST_CONTAINER'):
        # write directly to host so that docker_run.sh can use `docker run --rm`
        os.makedirs('/wikimedia/varnish/tmp', exist_ok=True)
        t = tempfile.mkstemp(dir='/wikimedia/varnish/tmp')
    else:
        t = tempfile.mkstemp()

    exitcode = 0
    with open(t[1], "w") as f:
        pf = os.popen(cmd)
        f.write(pf.read())
        status = pf.close()
        if status is not None:
            exitcode = os.waitstatus_to_exitcode(status)

    print("Test output saved to {}".format(t[1]))
    print(
        "If you want to fix your tests and re-run without recompiling pcc, run as follows:"
    )
    print(f"python3 run.py {hostname} {pcc_url}")

    sys.exit(exitcode)


if __name__ == "__main__":
    if len(sys.argv) < 3:
        usage = "Usage: {} <hostname> <change_num_or_pcc_url> [pcc_path] [vtc_file_glob]"
        print(usage.format(sys.argv[0]))
        sys.exit(1)

    if len(sys.argv) == 4:
        pcc_path = sys.argv[3]
    else:
        pcc_path = "../../../../utils/pcc"

    if len(sys.argv) == 5:
        vtc_file_glob = sys.argv[4]
    else:
        vtc_file_glob = ""

    main(sys.argv[1], sys.argv[2], pcc_path, vtc_file_glob)
