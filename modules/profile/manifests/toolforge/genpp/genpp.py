# genpp.py profile edition!

import collections
import subprocess
import functools
import os
import gzip
import sys
import logging

from jinja2 import Environment, FileSystemLoader

logger = logging.getLogger("genpp")

basedir = os.path.dirname(__file__)
moduledir = basedir.rsplit("modules", 1)[0] + "modules"
cachedir = os.path.join(basedir, ".cache")

env = Environment(
    loader=FileSystemLoader(os.path.join(basedir, "jinja")), keep_trailing_newline=True
)

env.filters["pline"] = lambda x: repr(x) + "," + (" " * (20 - len(x)))
env.filters["pydictsort"] = lambda x: sorted(
    x.items(), key=lambda y: (y[0].split("-", 1)[1].lower(), y)
)


try:
    os.makedirs(cachedir)
except OSError:
    pass

releases = collections.OrderedDict(
    [
        ("trusty", "http://packages.ubuntu.com/trusty"),
        ("jessie", "https://packages.debian.org/jessie"),
        ("stretch", "https://packages.debian.org/stretch"),
    ]
)


@functools.lru_cache()
def load_release(release):
    fn = os.path.join(cachedir, release + ".txt.gz")
    if not os.path.exists(fn):
        logger.info("Downloading release file for {}".format(release))
        url = releases[release] + "/allpackages?format=txt.gz"
        subprocess.check_output(["wget", url, "-O", fn])

    with gzip.open(fn, mode="rt", encoding="utf-8") as f:
        # skip header
        for i in range(6):
            next(f)
        packages = {}
        for line in f:
            name, version, desc = line.strip().split(" ", 2)
            version = version[1:].split("-")[0].split("+")[0]
            packages[name] = version

        return packages


def get_version(package, release):
    return load_release(release).get(package)


def pp_path(class_):
    parts = class_.split("::")
    if len(parts) == 1:
        raise Exception("Puppet class must be inside a module")
    parts[-1] += ".pp"
    return os.path.join(moduledir, parts[0], "manifests", *parts[1:])


def write_pp(module, release, environment, packages):
    class_ = "profile::toolforge::genpp::{module}_{env}_{release}".format(
        module=module, env=environment, release=release
    )
    path = pp_path(class_)
    template = env.get_template("packageclass.pp.jinja")
    stream = template.stream(
        {
            "class": class_,
            "command": " ".join(sys.argv),
            "module": module,
            "release": release,
            "environment": environment,
            "packages": packages,
        }
    )
    stream.dump(open(path, "w", encoding="utf-8"))
    logger.info("Wrote class {} to {}".format(class_, path))


def write_report(module, environments):
    path = os.path.join(basedir, "report-{}.html".format(module))
    template = env.get_template("report.html")
    stream = template.stream(
        {"module": module, "releases": releases, "envs": environments}
    )
    stream.dump(open(path, "w", encoding="utf-8"))
    logger.info("Wrote report to {}".format(path))
