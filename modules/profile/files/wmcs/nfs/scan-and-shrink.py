#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
#
#  A rudimentary and ill-mannered script to patrol user file usage. Originally
#  implemented to manage exploding NFS usage in PAWS.
#
#  Currently:
#   Locate single, gigantic files and move them to a 'trash can' directory
#   where they are queued for future deletion.
#
#  Todo:
#   Detect home directories that are just generally huge without individual
#   huge files; flag them for future attention someplace.
#

import argparse
import logging
import os
import shutil
from datetime import datetime
from os import listdir

SCORE_THRESHOLD = 3

logger = logging.getLogger(__name__)
logging.basicConfig(filename="/var/log/scan-and-shrink.log", level=logging.INFO)


# this is designed to search a set of home directories. So it doesn't actually
#  look at files in the top scanpath directory, only in subdirs.
def scan(maxfilesize: int, maxdirsize: int, scanpath: str, trashpath: str, dryrun: bool):
    home_scores = {}
    for userhome in listdir(scanpath):
        home_scores[userhome] = 0
        totaldirsize = 0
        sizes = {}

        for root, dirs, files in os.walk(os.path.join(scanpath, userhome), topdown=False):
            if "freeroot" in dirs:
                logger.warning(f"Found freeroot dir in {userhome}")
                home_scores[userhome] += 1
            for name in files:
                if not os.path.islink(os.path.join(root, name)):
                    try:
                        file_size = os.path.getsize(os.path.join(root, name))
                    except OSError:
                        logger.info("Failed to stat %s, skipping" % os.path.join(root, name))
                        continue
                    sizes[os.path.join(root, name)] = file_size
        for filepath, filesize in sorted(sizes.items(), key=lambda item: item[1]):
            if filesize > maxfilesize:
                local_path = os.path.dirname(filepath.replace(scanpath, ""))
                file_name = os.path.basename(filepath.replace(scanpath, ""))
                dest_path = trashpath + local_path + "/" + file_name

                if dryrun:
                    logger.info(f"{filepath} has size {filesize}, would move to {dest_path}")
                else:
                    os.makedirs(trashpath + local_path, exist_ok=True)
                    try:
                        os.rename(filepath, dest_path)
                        with open(filepath, "w") as removed:
                            removed.write(
                                "This file has been removed to manage user storage "
                                "size https://phabricator.wikimedia.org/T327936\n"
                            )
                    except OSError:
                        logger.info("Failed to move %s, skipping" % filepath)
            else:
                totaldirsize += filesize
        if totaldirsize > maxdirsize:
            logger.warning(f"Found oversized dir {userhome} size {totaldirsize}")
            home_scores[userhome] += int(totaldirsize / maxdirsize)

    for userhome, score in home_scores.items():
        if score >= SCORE_THRESHOLD:
            homedir = os.path.join(scanpath, userhome)
            dest_path = os.path.join(trashpath, userhome)
            if dryrun:
                logger.info(f"{userhome} has score {score}, would move to {dest_path}")
            else:
                shutil.move(homedir, dest_path)
                os.mkdir(homedir)
                readme = os.path.join(homedir, "README")
                date = datetime.today().strftime("%Y-%m-%d")
                with open(readme, "w") as f:
                    f.write(
                        "This notebook has been removed to manage user storage "
                        f"size.\nIt may be recoverable for a few days after {date}.\n"
                        "For a recovery attempt, contact cloud admins or comment on "
                        "https://phabricator.wikimedia.org/T327936\n"
                    )
                # Make sure user doesn't write more things here
                os.chmod(homedir, 0o444)


def main():
    parser = argparse.ArgumentParser(description="Scan disk usage and move large files")
    parser.add_argument(
        "-d",
        "--dry-run",
        action="store_true",
        help="Log potential actions but don't move anything",
    )
    parser.add_argument(
        "--maxfilesize", help="Move files larger than this. In MiB", type=int, default="1000"
    )
    parser.add_argument(
        "--maxdirsize",
        help="Score top-level dirs larger than this. In MiB",
        type=int,
        default="5000",
    )
    parser.add_argument("--trashpath", help="Large files are moved here", required=True)
    parser.add_argument("--scanpath", help="Path to scan (recursive)", required=True)
    args = parser.parse_args()

    scan(
        args.maxfilesize * 1024 * 1024,
        args.maxdirsize * 1024 * 1024,
        args.scanpath,
        args.trashpath,
        args.dry_run,
    )
    exit(0)


if __name__ == "__main__":
    main()
