#!/usr/bin/env python3
"""validate data.yaml against schema.yaml"""

from pathlib import Path

import yaml
import re

from yamllint.config import YamlLintConfig
from yamllint.linter import run

from jsonschema import FormatChecker, validate, ValidationError


class NoDatesSafeLoader(yaml.SafeLoader):
    """Disable parsing dates
    By default PyYAML will automatically cast the expiry_date to a datetime
    object which will fail the jsonschema format check (str_types = str):
        https://github.com/Julian/jsonschema/blob/master/jsonschema/_format.py#L331-L335
    This occurs because as jsonschema dose not have a datetime type.  instead
    it has a string type with a date format.
    Stolen from:
        https://stackoverflow.com/a/37958106/3075306"""
    @classmethod
    def remove_implicit_resolver(cls, tag_to_remove):
        """remove resolver"""
        if 'yaml_implicit_resolvers' not in cls.__dict__:
            cls.yaml_implicit_resolvers = cls.yaml_implicit_resolvers.copy()
        for first_letter, mappings in cls.yaml_implicit_resolvers.items():
            cls.yaml_implicit_resolvers[first_letter] = [
                (tag, regexp) for tag, regexp in mappings if tag != tag_to_remove]


YAML_LINT_CONFIG = """---
extends: default
rules:
    line-length: disable
    indentation: disable
    comments-indentation: disable
"""


def main():
    """Main Entry point"""
    ansi_fail = '\033[91m'
    ansi_ok = '\033[92m'
    ansi_end = '\033[0m'
    yamllint_error = False
    datelint_error = False

    NoDatesSafeLoader.remove_implicit_resolver('tag:yaml.org,2002:timestamp')
    yamllint_config = YamlLintConfig(YAML_LINT_CONFIG)

    schema_path = Path(__file__).parent / 'schema.yaml'
    data_path = Path(__file__).parent / 'data.yaml'

    try:
        # Ensure dates are quoted so that we don't hit a Ruby bug with
        # safe_load, https://github.com/ruby/psych/issues/262, we can't do this
        # check with yamllint, because pyyaml also parses dates, :(.
        with open(data_path, "r") as f:
            for i, line in enumerate(f, start=1):
                match = re.search("^ +(expiry_date: \\d{4}-\\d{2}-\\d{2})$", line)
                if match:
                    datelint_error = True
                    print(
                        "{}FAIL:{} {} '{}' {}".format(
                            ansi_fail,
                            i,
                            "dates must be quoted",
                            match.group(1),
                            ansi_end,
                        )
                    )
        if datelint_error:
            return 1

        for problem in run(data_path.read_text(), yamllint_config):
            yamllint_error = True
            print('{}FAIL:{} {}{}'.format(
                ansi_fail, problem.line, problem.desc, ansi_end))
        if yamllint_error:
            return 1

        schema = yaml.safe_load(open(schema_path))
        # don't convert dates
        data = yaml.load(open(data_path), Loader=NoDatesSafeLoader)
        validate(data, schema, format_checker=FormatChecker())
    except yaml.YAMLError as error:
        print('{}FAIL: unable load yaml file:\n{}{}'.format(
            ansi_fail, error, ansi_end))
        return 1
    except ValidationError as error:
        print('{}FAIL: unable to validate data.yaml:\n{}{}'.format(
            ansi_fail, error, ansi_end))
        return 1
    print('{}PASS: data.yaml validates{}'.format(
        ansi_ok, ansi_end))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
