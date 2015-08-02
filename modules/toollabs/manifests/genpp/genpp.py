import subprocess
import functools
import os
import gzip
import re
import sys
import logging
import pprint

logger = logging.getLogger('genpp')

basedir = os.path.split(__file__)[0]
moduledir = basedir.rsplit("modules", 1)[0] + "modules"
cachedir = os.path.join(basedir, ".cache")

try:
    os.makedirs(cachedir)
except IOError:
    pass

releases = {
    'precise': 'http://packages.ubuntu.com/precise/allpackages?format=txt.gz',
    'trusty': 'http://packages.ubuntu.com/trusty/allpackages?format=txt.gz',
    'jessie': 'https://packages.debian.org/jessie/allpackages?format=txt.gz'
}


@functools.lru_cache()
def load_release(release):
    fn = os.path.join(cachedir, release + ".txt.gz")
    if not os.path.exists(fn):
        logger.info("Downloading release file for {}".format(release))
        url = releases[release]
        subprocess.check_output(["wget", url, "-O", fn])

    with gzip.open(fn, mode='rt', encoding='utf-8') as f:
        # skip header
        for i in range(6):
            next(f)
        return set(line.split()[0] for line in f)


def get_best_package(release, options):
    """
    Returns the best-match package from options (first hit) or None
    if no candidate is found.
    """
    packages = load_release(release)
    if not isinstance(options, list):
        options = [options]

    for option in options:
        if option in packages:
            return option


def get_python_packages(release, postfix):
    packages = [get_best_package(release, "python-" + postfix),
                get_best_package(release, "python3-" + postfix)]
    return [package for package in packages if package]


def pp_path(class_):
    parts = class_.split("::")
    if len(parts) == 1:
        raise Exception("Puppet class must be inside a module")
    parts[-1] += ".pp"
    return os.path.join(moduledir, parts[0], "manifests", *parts[1:])


def write_pp(class_, packages):
    path = pp_path(class_)
    with open(path, 'w', encoding='utf-8') as f:
        f.write("""# Class: %(class)s
#
# This file was auto-generated by genpp.py using the following command:
# %(cmd)s
#
# Please do not edit manually!

class %(class)s {
    package { [
""" % {'class': class_, 'cmd': " ".join(sys.argv)})
        for package in sorted(packages):
            f.write("        " + repr(package) + ",\n")
        f.write("""    ]:
        ensure => latest,
    }
}""")
    logger.info("Wrote class {} to {}".format(class_, path))
