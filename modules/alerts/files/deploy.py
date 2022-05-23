#!/usr/bin/python3

import argparse
import fnmatch
import logging
import pathlib
import re
import shutil
import sys

log = logging.getLogger()


def get_log_level(args_level):
    return {
        None: logging.ERROR,
        1: logging.WARN,
        2: logging.INFO,
        3: logging.DEBUG,
    }.get(args_level, logging.WARN)


def deploy_rulefiles(src_paths, dest_dir, src_dir):
    """Copy all files in src_paths to dest_dir.

    Since Prometheus doesn't support recursive globbing, the destination files will be "flattened"
    by replacing '/' with '_' in the file path (relative to src_dir)."""

    result = []

    for src_path in src_paths:
        rel_dest = src_path.relative_to(src_dir).as_posix().replace("/", "_")
        result.append(pathlib.Path(rel_dest))

        dest_path = dest_dir.joinpath(rel_dest)

        log.info("Deploying %s to %s", src_path, dest_path)

        shutil.copy2(src_path.as_posix(), dest_path.as_posix())

    return result


def cleanup_dir(target_path, expected_paths):
    """Clean up target_path of all files not in expected_paths."""

    for path in target_path.glob("*"):
        if not path.is_file():
            continue

        if path.relative_to(target_path) not in expected_paths:
            log.warning("Removing %s", path)
            path.unlink()


def all_rulefiles(paths):
    """Return all alerting rule files."""
    files = []

    for path in paths:
        non_test_files = set(path.glob("**/*.yaml")) - set(path.glob("**/*_test.yaml"))
        files.extend(non_test_files)

    return files


def get_tag(fobj, name):
    """Read tag 'name' from fobj "header". The header ends when a non-comment or non-empty line, the
    rest is ignored. Return None on tag not found."""

    # FIXME Use format strings when all Prometheus hosts run >= Buster
    tag_re = re.compile("^# *{name}: *(.+)$".format(name=name))

    for line in fobj:
        m = tag_re.match(line)
        if m:
            return m.group(1)
        # stop looking after comments and empty lines
        if not line.startswith("#") and not line.startswith(" "):
            return None
    return None


def filter_tag(files, tag_name, tag_value, default):
    """Scan each of 'files' for 'tag_name' matching 'tag_value'. A file without tags is assumed to
    have 'tag_name' with value 'default'. The tag specification within
    the file can have multiple comma-separated values. Each tag found
    will be matched against tag_value with fnmatch.

    Return the filtered list."""

    res = []
    for filename in files:
        with open(filename.as_posix()) as f:
            tag = get_tag(f, tag_name)
            if tag is None:
                # tag not found, but we're looking for its default value
                if tag_value == default:
                    res.append(filename)
            else:
                tags = re.split(r",\s*", tag)
                # tag found and has the value we're looking for
                if tag_value in tags:
                    res.append(filename)

                # scan for matches in tag values
                for tag_pattern in tags:
                    if fnmatch.fnmatch(tag_value, tag_pattern):
                        res.append(filename)

    return res


def main():
    parser = argparse.ArgumentParser(description="Deploy alerting rules")
    parser.add_argument(
        "-v", "--verbose", action="count", help="Increase verbosity (repeated)"
    )
    parser.add_argument(
        "--alerts-dir",
        default="/srv/alerts.git",
        metavar="PATH",
        help="Deploy files from PATH",
    )
    parser.add_argument(
        "--cleanup",
        action="store_true",
        default=False,
        help="Clean up DEPLOY_DIR of stray files",
    )
    parser.add_argument(
        "--deploy-tag",
        metavar="NAME",
        default="local",
        help="Deploy alert files with 'deploy-tag' NAME. Files without 'deploy-tag'"
        " will be considered to have tag 'local'.",
    )
    parser.add_argument(
        "--deploy-site",
        metavar="NAME",
        default=None,
        help="Deploy alert files with 'deploy-site' NAME. Alerts with no"
        " deploy-site tag will be deployed.",
    )
    parser.add_argument(
        "deploy_dir", metavar="DEPLOY_DIR", help="Deploy alerts to DEPLOY_DIR"
    )
    args = parser.parse_args()

    logging.basicConfig(level=get_log_level(args.verbose))

    deploy_dir = pathlib.Path(args.deploy_dir)
    deploy_dir.mkdir(parents=True, exist_ok=True)

    alerts_dir = pathlib.Path(args.alerts_dir)

    subdirs = [x for x in alerts_dir.glob("[!.]*") if x.is_dir()]

    log.debug("Inspecting %r", subdirs)
    rulefiles = all_rulefiles(subdirs)
    rulefiles = filter_tag(rulefiles, "deploy-tag", args.deploy_tag, "local")
    if args.deploy_site is not None:
        rulefiles = filter_tag(
            rulefiles, "deploy-site", args.deploy_site, args.deploy_site
        )
    log.debug("Found rulefiles %r", rulefiles)
    deployed_paths = deploy_rulefiles(rulefiles, deploy_dir, alerts_dir)

    if args.cleanup:
        cleanup_dir(deploy_dir, deployed_paths)

    # Report success when something has been deployed
    return 0 if len(deployed_paths) > 0 else 42


if __name__ == "__main__":
    sys.exit(main())
