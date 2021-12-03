#!/usr/bin/python3

import argparse
import sys
import glob
import tempfile
import subprocess
import os
import filecmp

import yaml


def load_and_validate(paths):
    res = []
    for path in paths:
        with open(path) as f:
            frag = yaml.safe_load(f)
        if not isinstance(frag, dict):
            raise ValueError("{} does not contain a yaml top level object".format(path))
        if "modules" not in frag:
            raise ValueError("{} must have a 'modules' top level object".format(path))
        res.append(frag)
    return res


def merge_fragments(fragments):
    res = {"modules": {}}
    # XXX check/warn for conflicting modules?
    for frag in fragments:
        res["modules"].update(frag["modules"])
    return res


def config_needs_update(config, fragments):
    config_mtime = os.stat(config).st_mtime
    for frag in fragments:
        if os.stat(frag).st_mtime > config_mtime:
            return True
    return False


def main():
    parser = argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument(
        "--onlyif",
        dest="onlyif",
        default=False,
        action="store_true",
        help="check if config.out needs updating",
    )
    parser.add_argument(
        "--config.out",
        dest="config_out",
        metavar="PATH",
        default="/etc/prometheus/blackbox.yml",
        help="store the configuration in PATH",
    )
    parser.add_argument(
        "--input.glob",
        dest="input_glob",
        default="/etc/prometheus/blackbox.yml.d/*.yml",
        metavar="GLOB",
        help="assemble the configuration from files matching GLOB",
    )
    parser.add_argument(
        "--bin",
        dest="bin",
        default="/usr/bin/prometheus-blackbox-exporter",
        metavar="PATH",
        help="use the binary at PATH for config validation",
    )
    args = parser.parse_args()

    input_paths = glob.glob(args.input_glob)
    if not input_paths:
        parser.error("No files matched for {}".format(args.input_glob))

    if args.onlyif:
        if config_needs_update(args.config_out, input_paths):
            return 0
        else:
            return 1

    fragments = load_and_validate(sorted(input_paths))
    out_config = merge_fragments(fragments)

    with tempfile.NamedTemporaryFile(
        mode="w", dir=os.path.dirname(args.config_out), delete=False
    ) as f:
        yaml.safe_dump(out_config, f, indent=4, default_flow_style=False)
        try:
            subprocess.check_output(
                [args.bin, "--config.check", "--config.file", f.name],
                stderr=subprocess.STDOUT,
            )
        except subprocess.CalledProcessError as e:
            print("Config validation failed:\n{}".format(e.output.decode("utf8")))
            os.unlink(f.name)
            return 2
        if filecmp.cmp(f.name, args.config_out):
            os.unlink(f.name)
        else:
            os.rename(f.name, args.config_out)
            os.chmod(args.config_out, 0o444)
        return 0


if __name__ == "__main__":
    sys.exit(main())
