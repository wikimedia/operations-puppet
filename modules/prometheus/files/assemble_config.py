#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0

# This program takes care of assembling together an "input_glob" of
# files into a "config_out" configuration path. The configuration is put
# together in a temporary file and passed to "validate_cmd" before
# writing. If validation fails then nothing is written.

# The --onlyif flag is useful when calling the script from Puppet
# "exec", specifically to recover from the following scenario:

# - a fragment changes, a refresh of the exec is triggered
# - the exec fails for some reason, the configuration is not updated
# - at the next puppet run the fragment doesn't change, therefore
#   the exec is not refreshed again
# - the old configuration is silently kept in place until a fragment
#   changes again

# The configuration is YAML based and an example is found below:
# modules:
#   blackbox:
#     validate_cmd: /usr/bin/prometheus-blackbox-exporter --config.check --config.file {}
#     input_glob: /etc/prometheus/blackbox.yml.d/*.yml
#     config_out: /etc/prometheus/blackbox.yml
#   pint:
#     validate_cmd: /usr/bin/pint --config {} config
#     input_glob: /etc/prometheus/pint.hcl.d/*.hcl
#     config_out: /etc/prometheus/pint.hcl

import argparse
import filecmp
import glob
import os
import shlex
import subprocess
import sys
import tempfile
import shutil

import yaml


class Module(object):
    TMPFILE_SUFFIX = None

    def __init__(self, obj):
        self.config_mode = "644"

        for k, v in obj.items():
            self.__setattr__(k, v)

        input_paths = glob.glob(self.input_glob)
        if not input_paths:
            raise ValueError(f"No files matched for {self.input_glob}")
        self.input_paths = input_paths

    def config_needs_update(self):
        if not os.path.exists(self.config_out):
            return True

        config_mtime = os.stat(self.config_out).st_mtime
        for frag in self.input_paths:
            if os.stat(frag).st_mtime > config_mtime:
                return True
        return False

    def write_config(self):
        config = self._assemble()

        with tempfile.NamedTemporaryFile(
            mode="w",
            suffix=self.TMPFILE_SUFFIX,
            dir=os.path.dirname(self.config_out),
        ) as f:
            self._write(config, f)
            f.flush()
            if not self.validate(f.name):
                return 2
            if not os.path.exists(self.config_out) or not filecmp.cmp(
                f.name, self.config_out
            ):
                shutil.copy(f.name, self.config_out)
                os.chmod(self.config_out, int(str(self.config_mode), 8))
            return 0

    def validate(self, path):
        try:
            subprocess.check_output(
                shlex.split(self.validate_cmd.format(path)),
                stderr=subprocess.STDOUT,
            )
        except subprocess.CalledProcessError as e:
            print("Config validation failed:\n{}".format(e.output.decode("utf8")))
            return False
        return True

    @staticmethod
    def from_config(name, config):
        if "modules" not in config:
            raise ValueError("'modules' not found in config")

        module_config = config["modules"].get(name)
        if not module_config:
            raise ValueError(f"Module {name} not found in config")

        module_class = MODULES.get(name)
        if module_class is None:
            raise ValueError(f"Unable to find class for module {name}")

        return module_class(module_config)


class Pint(Module):
    # Pint requires config paths with file format appended
    TMPFILE_SUFFIX = ".hcl"

    def _assemble(self):
        frags = []
        for path in self.input_paths:
            with open(path) as f:
                frags.extend(f.readlines())
        return frags

    def _write(self, config, fd):
        fd.writelines(config)


class Blackbox(Module):
    def _assemble(self):
        frags = []
        for path in self.input_paths:
            with open(path) as f:
                frag = yaml.safe_load(f)
            if not isinstance(frag, dict):
                raise ValueError(f"{path} does not contain a yaml top level object")
            if "modules" not in frag:
                raise ValueError(f"{path} must have a 'modules' top level object")
            frags.append(frag)

        res = {"modules": {}}
        for frag in frags:
            res["modules"].update(frag["modules"])
        return res

    def _write(self, config, fd):
        return yaml.safe_dump(config, fd, indent=4, default_flow_style=False)


MODULES = {"blackbox": Blackbox, "pint": Pint}


def main():
    parser = argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument(
        "--onlyif",
        dest="onlyif",
        default=False,
        action="store_true",
        help="check if configuration needs updating (based on mtime)",
    )
    parser.add_argument(
        "--config",
        dest="config",
        metavar="PATH",
        default="/etc/prometheus/assemble-config.yaml",
        help="read config from PATH",
    )
    parser.add_argument(
        "module",
        metavar="MODULE",
        help="use MODULE from config to validate",
    )
    args = parser.parse_args()

    with open(args.config) as f:
        config = yaml.safe_load(f)

    module = Module.from_config(args.module, config)

    if args.onlyif:
        if module.config_needs_update():
            return 0
        else:
            return 1

    return module.write_config()


if __name__ == "__main__":
    sys.exit(main())
