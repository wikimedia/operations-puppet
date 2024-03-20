#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
"""Translate all server fact files into yaml and aggregate into a tarball.
   Facts are then transferred via a different script to puppet compiler
   nodes."""


from io import BytesIO
import json
from pathlib import Path
import tarfile
import time
import yaml

outfile = Path("/tmp/puppet-facts-export.tar.xz")
factsdir = Path("/var/lib/puppetserver/server_data/facts")


def redact(facts: dict, keyname: str):
    if keyname in facts["values"]:
        facts["values"][keyname] = "REDACTED"


with tarfile.open(outfile, "w:xz") as yamltarfile:
    for jsonfactfilepath in factsdir.iterdir():
        if jsonfactfilepath.suffix == ".json":

            with open(jsonfactfilepath) as jsonfactfile:
                facts = json.load(jsonfactfile)

                # Remove potentially sensitive facts
                #  (Some of this is legacy from when we ran
                #   this process on production hardware)
                redact(facts, "uniqueid")
                redact(facts, "boardserialnumber")
                redact(facts, "boardproductname")
                redact(facts, "serialnumber")
                for key in facts["values"]:
                    if key.endswith("trusted"):
                        del facts["values"][key]

                yamlfacts = yaml.dump(facts).encode("utf8")
                tarinfo = tarfile.TarInfo(jsonfactfilepath.stem + ".yaml")
                tarinfo.mtime = int(time.time())
                tarinfo.size = len(yamlfacts)
                yamltarfile.addfile(tarinfo, BytesIO(yamlfacts))

print("puppet facts sanitized and exported at %s" % outfile)
