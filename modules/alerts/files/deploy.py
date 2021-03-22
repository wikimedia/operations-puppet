#!/usr/bin/python3

import argparse
import logging
import pathlib
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

        shutil.copyfile(src_path.as_posix(), dest_path.as_posix())

    return result


def cleanup_dir(target_path, expected_paths):
    """Clean up target_path of all files not in expected_paths."""

    for path in target_path.glob("*"):
        if path.relative_to(target_path) not in expected_paths:
            log.warning("Removing %s", path)
            path.unlink()


def all_rulefiles(paths):
    """Return all alerting rule files."""
    files = []

    for path in paths:
        files.extend(path.glob("**/*[!_test].yaml"))

    return files


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
    log.debug("Found rulefiles %r", rulefiles)
    deployed_paths = deploy_rulefiles(rulefiles, deploy_dir, alerts_dir)

    if args.cleanup:
        cleanup_dir(deploy_dir, deployed_paths)

    # Report success when something has been deployed
    return 0 if len(deployed_paths) > 0 else 1


if __name__ == "__main__":
    sys.exit(main())
