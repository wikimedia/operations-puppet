#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0

import argparse
import os
import sys


def main() -> int:
    opts = parse_args()
    if opts.needle == "":
        print("ERROR: needle cannot be empty", file=sys.stderr)

    with open(opts.stack, "rb") as f:
        loc = find_needle(f, opts.needle)
        if loc < 0:
            print("ERROR: needle not found", file=sys.stderr)
            return 1
        lower_loc = lower_bound(f, opts.needle, loc)
        assert lower_loc >= 0
        upper_loc = upper_bound(f, opts.needle, loc)
        assert upper_loc <= max_pos(f) + 1

        # sendfile() on sys.stdout produces EINVAL if stdout has O_APPEND set,
        # so let's open another.
        o = os.open("/dev/stdout", os.O_WRONLY)
        os.sendfile(o, f.fileno(), lower_loc, upper_loc - lower_loc)
        os.close(o)
    return 0


def parse_args() -> argparse.Namespace:
    """Parse cmdline arguments.

    Returns:
        argparse.Namespace: parsed arguments.
    """
    parser = argparse.ArgumentParser(
        prog="bsection",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
        description="Binary-search log files for a section containing a common prefix.",
    )
    parser.add_argument(
        "needle",
        help="Line prefix to find. This portion of the line must be in sorted "
        "order in the file (e.g. a leading timestamp).",
    )
    parser.add_argument(
        "stack",
        help="Input file. All lines must be >= the length of needle. "
        "Assumed to be in utf8-8 encoding.",
    )
    return parser.parse_args()


def find_needle(f, needle: str) -> int:
    """Binary search a file for any line starting with a prefix.

    Arguments:
        f (file): File to search.
        needle (str): The line prefix to find.

    Returns:
        int: File offset of the first byte of the line. -1 if needle is not found.
    """
    start = 0
    max_idx = end = max_pos(f)
    old_pos = -1
    while True:
        f.seek(int((start + end) / 2))
        pos = find_line_start(f)
        if old_pos == pos:
            # Binary search is making no progress, switch tactic
            break

        check = check_needle(f, needle)
        if check == 0:
            return pos
        elif check < 0:
            end = pos
        elif check > 0:
            start = pos

        old_pos = pos

    # line-by-line search the remaining section
    while True:
        f.readline()
        pos = f.tell()
        if pos >= end or pos >= max_idx:
            return -1
        if check_needle(f, needle) == 0:
            return pos


def lower_bound(f, needle: str, end: int) -> int:
    """Binary search a file for the first line starting with a prefix.

    This function assumes that the supplied upper-bound is the start of a line containing
    the prefix (typically the return-value of find_needle()).

    Arguments:
        f (file): File to search.
        needle (str): The line prefix to find.
        end (int): Upper-bound file offset of the search area.

    Returns:
        int: File offset of the first byte of the line. If the prefix is not found in the
        search area, then this will be equal to the supplied upper-bound.
    """
    start = 0
    old_pos = -1
    while True:
        f.seek(int((start + end) / 2))
        pos = find_line_start(f)
        if old_pos == pos:
            # Binary search is making no progress, switch tactic
            break

        check = check_needle(f, needle)
        assert check >= 0, "Needle contains unsorted portion"
        if check == 0:
            if pos == 0:
                # Handle case where first line matches
                return 0
            # Found the needle, set the end to the previous line
            f.seek(pos - 1)
            end = find_line_start(f)
        else:
            start = pos

        old_pos = pos

    # line-by-line search the remaining section
    while check_needle(f, needle) != 0:
        f.readline()
    return f.tell()


def upper_bound(f, needle: str, start: int) -> int:
    """Binary search a file for the last line starting with a prefix.

    This function assumes that the supplied lower-bound is the start of a line containing
    the prefix (typically the return-value of find_needle()).

    Arguments:
        f (file): File to search.
        needle (str): The line prefix to find.
        start (int): Lower-bound file offset of the search area.

    Returns:
        int: File offset of the first byte _after_ the line.
    """
    max_idx = end = max_pos(f)
    old_pos = -1
    while True:
        f.seek(int((start + end) / 2))
        pos = find_line_start(f)
        if old_pos == pos:
            # Binary search is making no progress, switch tactic
            break

        check = check_needle(f, needle)
        assert check <= 0, "Needle contains unsorted portion"
        if check == 0:
            # Found the needle, set the start to the next line
            f.readline()
            start = f.tell()
            if start > max_idx:
                # Handle case where the last line matches
                return start
        else:
            end = pos

        old_pos = pos

    # line-by-line search the remaining section
    while check_needle(f, needle) == 0:
        f.readline()
    return f.tell()


def max_pos(f) -> int:
    """Find the last byte of the file

    Arguments:
        f (file): File to search.

    Returns:
        int: Offset of the last byte in the file.
    """
    # Seeking with (0, os.SEEK_END) will point 1B past the end of the file,
    # so instead seek -1.
    pos_max = f.seek(-1, os.SEEK_END)
    f.seek(0)
    return pos_max


def find_line_start(f) -> int:
    """Find the start of the current line

    Arguments:
        f (file): File to search.

    Returns:
        int: Offset of the first byte of the current line.
    """
    orig_pos = pos = f.tell()
    while pos > 0:
        c = f.read(1)
        f.seek(pos)  # Rewind read
        # Guard against case where the initial position is a newline
        if pos != orig_pos and c == b"\n":
            # Found a previous newline, increment forward again and then return.
            f.seek(pos + 1)
            break
        f.seek(pos - 1)
        pos = f.tell()
    # Either we're at position 0, or just after a \n
    return f.tell()


def check_needle(f, needle: str) -> int:
    """Compare the current line in the file to needle.

    Arguments:
        f (file): File to search.
        needle (str): Needle to find.

    Returns:
        int: 0 if the line starts with needle, -1 if needle sorts before line,
            1 if needle sorts after it.
    """
    line = peek_line(f)[: len(needle)]
    assert len(line) >= len(needle), "Prefix longer than line at %d: %r" % (
        f.tell(),
        f.readline(),
    )
    if line.startswith(needle):
        return 0
    if needle < line:
        return -1
    return 1


def peek_line(f) -> str:
    """Read one line from file, and return to the initial position.

    Arguments:
        f (file): File to read from.

    Returns:
        str: Contents of file from current position to the next newline.
    """
    pos = f.tell()
    s = f.readline().decode("utf8")
    f.seek(pos)
    return s


if __name__ == "__main__":
    sys.exit(main())
