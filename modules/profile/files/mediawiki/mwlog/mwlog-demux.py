#!/usr/bin/python3

# Accept "JSON lines" (i.e. one object per line) on standard input and demux
# them into plaintext files under --basedir.
# Filename is taken from 'program' attribute, and the file content from 'msg'
# attribute.

# This script is based on 'demux.py' from udp2log and is meant to provide
# backwards compatibility when used with kafkatee to receive logs.

import argparse
import json
import os
import re
import sys


UNSAFE_CHARS = str.maketrans("./", "__")
ASCII_PRINTABLE_RE = re.compile(r"^[\040-\176]*$")


def parse_line(line, prefix):
    prefixlen = len(prefix)

    try:
        parsed = json.loads(line)
    except json.decoder.JSONDecodeError:
        return (None, None)

    text = parsed.get("msg")
    name = parsed.get("program")
    if not text or not name:
        return (None, None)

    name = str.translate(name, UNSAFE_CHARS)
    if not name.startswith(prefix):
        return (None, None)
    name = name[prefixlen:]

    if not ASCII_PRINTABLE_RE.match(name):
        return (None, None)

    return (name, text)


def main():
    open_files = {}

    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--basedir",
        default="/srv/mw-log-kafka",
        help="Base directory to write files to",
    )
    parser.add_argument(
        "--program-prefix",
        default="mwlog-",
        help="Prefix to strip from 'program' attribute before extracting file name",
    )
    args = parser.parse_args()

    if not os.access(args.basedir, os.W_OK):
        raise Exception("Unable to write to " + args.basedir)

    while True:
        # Use readline() not next() to avoid python's buffering
        line = sys.stdin.readline()
        if not line:
            break

        try:
            channel, text = parse_line(line, args.program_prefix)
        except Exception:
            continue

        if not channel or not text:
            continue

        channel += ".log"
        try:
            if channel in open_files:
                f = open_files[channel]
            else:
                f = open(os.path.join(args.basedir, channel), "a")
                open_files[channel] = f
            f.write(text + "\n")
            f.flush()
        except KeyboardInterrupt:
            break
        except Exception:
            # Close the file and delete it from the map,
            # in case there's something wrong with it
            if channel in open_files:
                try:
                    open_files[channel].close()
                except Exception:
                    pass
                del open_files[channel]


if __name__ == "__main__":
    sys.exit(main())
