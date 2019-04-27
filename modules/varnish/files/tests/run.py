#!/usr/bin/env python3

import os
import re
import sys
import tempfile

import requests

DC = ("eqiad", "codfw", "esams", "ulsfo", "eqsin")
CLUSTERS = ("text", "upload")
PATH_RE = re.compile("^(/etc/varnish/|/usr/share/varnish/)")
COMPILER_RE = re.compile(
    ".*(https://puppet-compiler.wmflabs.org/compiler[0-9]{4}/[0-9]+/)"
)
PCC = "../../../../utils/pcc"
TIMEOUT = 30

CC_COMMAND = (
    "exec gcc -std=gnu99 -g -O2 -fstack-protector-strong -Wformat "
    "-Werror=format-security -Wall -pthread -fpic -shared -Wl,-x "
    "-o %o %s -lmaxminddb"
)


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


def get_pcc_url(hostname, patch_id):
    cmd = " ".join((PCC, patch_id, hostname))
    for line in os.popen(cmd).readlines():
        match = COMPILER_RE.match(line)
        if match:
            return match.group(1)

    raise Exception("Issues with get_pcc_url()")


def dump_files(url, hostname):
    catalog_url = "{}/{}/change.{}.pson".format(url, hostname, hostname)
    print("\tCatalog URL: {}".format(catalog_url))

    catalog = requests.get(catalog_url, timeout=TIMEOUT).json()
    for resource in catalog["resources"]:
        if resource["type"] != "File":
            continue
        if PATH_RE.match(resource["title"]) is None:
            continue
        if "content" not in resource["parameters"]:
            continue
        path = resource["title"].lstrip("/")
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "wb") as f:
            print("\tCreating {}".format(path))
            f.write(resource["parameters"]["content"].encode("utf-8"))


def main(hostname, patch_id="HEAD"):
    print("[*] running PCC for change {}...".format(patch_id))
    pcc_url = get_pcc_url(hostname, patch_id)
    print("\tPCC URL: {}\n".format(pcc_url))

    print("[*] Dumping files...")
    dump_files(pcc_url, hostname)
    print()

    print("[*] Finding cluster...")
    cluster = find_cluster(hostname)
    print("\t{} is a cache_{} host\n".format(hostname, cluster))

    print("[*] Running varnishtest (this might take a while)...")
    cwd = os.getcwd()
    vcl_path = "{}/usr/share/varnish/tests:{}/etc/varnish".format(cwd, cwd)
    cmd = "{} -Dcc_command='{}' -Dbasepath={} -Dvcl_path={} {}/*.vtc".format(
        "sudo varnishtest -k", CC_COMMAND, cwd, vcl_path, cluster
    )
    print("\t{}\n".format(cmd))
    t = tempfile.mkstemp()
    with open(t[1], "w") as f:
        f.write(os.popen(cmd).read())
    print("Test output saved to {}".format(t[1]))


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: {} hostname patch_id".format(sys.argv[0]))
        sys.exit(1)

    main(sys.argv[1], sys.argv[2])
