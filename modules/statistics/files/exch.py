#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
# Swap two paths in one atomic step, as `exch` (util-linux) and `mv --exchange` (coreutils) do.
# Bookworm has neither. On trixie, use /usr/bin/exch and remove this script. See renameat2(2).
import ctypes
import os
import sys

AT_FDCWD = -100           # <fcntl.h>: relative paths start at the current directory.
RENAME_EXCHANGE = 1 << 1  # <stdio.h>: swap the two paths.

path1, path2 = sys.argv[1:]
libc = ctypes.CDLL("libc.so.6", use_errno=True)
result = libc.renameat2(AT_FDCWD, os.fsencode(path1),
                        AT_FDCWD, os.fsencode(path2),
                        RENAME_EXCHANGE)
if result != 0:
    sys.exit(f"exch: cannot swap {path1} and {path2}: {os.strerror(ctypes.get_errno())}")
