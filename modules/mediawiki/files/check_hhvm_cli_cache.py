#!/usr/bin/python
# -*- coding: utf-8 -*-
import argparse
import sys
import os

hhvm_cli_cache = "/var/cache/hhvm/cli.hhbc.sq3"


def main():
    parser = argparse.ArgumentParser(description="Check HHVM CLI cache")
    parser.add_argument('-w', type=int, help="Warning threshold in MiB", required=True)
    parser.add_argument('-c', type=int, help="Critical threshold in MiB", required=True)
    args = parser.parse_args()

    warning_threshold = args.w * 1048576
    critical_threshold = args.c * 1048576

    try:
        cache_size = os.path.getsize(hhvm_cli_cache)
    except OSError as e:
        print("UNKNOWN: error reading CLI cache")
        sys.exit(3)

    if cache_size > critical_threshold:
        print("CRITICAL: HHVM CLI cache is %d bytes" % cache_size)
        sys.exit(2)
    elif cache_size > warning_threshold:
        print("WARNING: HHVM CLI cache is %d bytes" % cache_size)
        sys.exit(1)
    else:
        print("OK: HHVM CLI cache is %d bytes" % cache_size)
        sys.exit(0)


if __name__ == '__main__':
    main()
