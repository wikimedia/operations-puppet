#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0

import sys
import shutil
import logging
import click
import re

from typing import List
from pathlib import Path
from itertools import chain

log = logging.getLogger()

LOG_LEVELS = ["DEBUG", "INFO", "WARNING", "ERROR"]


def get_all_rulefiles(paths: Path, exclude_pattern: str = None) -> List[Path]:
    """Return all yaml files in a dir"""
    result = []
    for file in chain(paths.rglob("*.yaml"), paths.rglob("*.yml")):
        if exclude_pattern and re.search(exclude_pattern, file.as_posix()):
            log.debug("Excluding file: %s", file)
            continue
        log.debug("Found rule file: %s", file)
        result.append(file)
    return result


def flattened_copy(
    src: Path, dst: Path, exclude_pattern: str = None
) -> List[Path]:
    """Copy src to dst, flattening the filename by replacing '/' with '_'."""
    copied = []
    dst.mkdir(exist_ok=True)
    for file in get_all_rulefiles(src, exclude_pattern=exclude_pattern):
        flattened_prefix = (
            file.relative_to(src).parent.as_posix().replace("/", "_")
        )
        target = (dst / f"{flattened_prefix}_{file.name}").with_suffix('.yaml')
        copied.append(target)
        log.info("Copying %s to %s", file, target)
        shutil.copy2(file, target)

    return copied


@click.command(
    help="""
    Copy all YAML files from a Sloth generate output directory to a flatten directory.
    This command recursively finds all '.yaml' files in the Sloth generate output
    directory and copies them into the flatten directory, preserving filenames.
    """
)
@click.option(
    "--manifests-dir",
    type=click.Path(exists=True, path_type=Path),
    default="/srv/app/",
    help="Directory containing manifest (YAML) files.",
)
@click.option(
    "--flatten-dir",
    type=click.Path(path_type=Path),
    default="/srv/app/flatten",
    help="Directory where YAML files will be copied (flattened, filenames only).",
)
@click.option(
    "--exclude-pattern",
    type=str,
    default=None,
    help="Regex pattern to exclude files from processing.",
)
@click.option(
    "--log-level",
    type=click.Choice(LOG_LEVELS, case_sensitive=False),
    default="INFO",
    help="Set logging level.",
)
def main(
    manifests_dir: Path,
    flatten_dir: Path,
    exclude_pattern: str,
    log_level: str,
) -> None:

    logging.basicConfig(
        level=getattr(logging, log_level.upper()),
        format="%(asctime)s | %(levelname)s | %(funcName)s | %(message)s",
        stream=sys.stderr,
    )

    flattened_copy(manifests_dir, flatten_dir, exclude_pattern)


if __name__ == "__main__":
    sys.exit(main())
