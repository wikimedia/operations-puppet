#!/usr/bin/env python3

import base64
import os
import re
import sys
import tempfile

import requests
import subprocess

from pathlib import Path

import toml

DC = ("eqiad", "codfw", "esams", "ulsfo", "eqsin", "drmrs", "magru")
CLUSTERS = ("text", "upload")
PATH_RE = re.compile("^(/etc/varnish/|/usr/share/varnish/|/etc/confd/.*_etc_varnish.*)")
COMPILER_RE = re.compile(
    ".*(https://puppet-compiler.wmflabs.org/output/[0-9]+/[0-9]+/)"
)
TIMEOUT = 30

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
        r = requests.get(url, timeout=TIMEOUT)
        if hostname in r.text:
            return cluster

    raise Exception("Unknown cluster for {}".format(hostname))


def get_pcc_url(hostname, patch_id, pcc):
    cmd = " ".join((pcc, "-N", patch_id, hostname))
    for line in os.popen(cmd).readlines():
        match = COMPILER_RE.match(line)
        if match:
            return match.group(1)

    raise Exception("Issues with get_pcc_url()")


def dump_files(url, hostname):
    catalog_url = "{}/{}/change.{}.pson.gz".format(url, hostname, hostname)
    print("\tCatalog URL: {}".format(catalog_url))

    catalog = requests.get(catalog_url, timeout=TIMEOUT).json()
    for resource in catalog["resources"]:
        if resource["type"] != "File":
            continue
        if PATH_RE.match(resource["title"]) is None:
            continue
        if "content" not in resource["parameters"]:
            continue
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


def main(hostname, patch_or_url, pcc):
    if patch_or_url.startswith("https://"):
        pcc_url = patch_or_url
    else:
        patch_id = patch_or_url
        print("[*] running PCC for change {}...".format(patch_id))
        pcc_url = get_pcc_url(hostname, patch_id, pcc)
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
    cmd = "{} -Dcc_command='{}' -Dbasepath={} -Dvcl_path={} {}/*.vtc".format(
        "sudo varnishtest -k", CC_COMMAND, PARENT_DIR, vcl_path, cluster_vtc_path
    )
    print("\t{}\n".format(cmd))
    t = tempfile.mkstemp()
    with open(t[1], "w") as f:
        f.write(os.popen(cmd).read())
    print("Test output saved to {}".format(t[1]))
    print(
        "If you want to fix your tests and re-run without recompiling pcc, run as follows:"
    )
    print(f"python3 run.py {hostname} {pcc_url}")


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: {} hostname patch_or_pcc_url [pcc_path]".format(sys.argv[0]))
        sys.exit(1)

    if len(sys.argv) == 4:
        pcc = sys.argv[3]
    else:
        pcc = "../../../../utils/pcc"

    main(sys.argv[1], sys.argv[2], pcc)
