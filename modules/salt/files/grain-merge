#!/usr/bin/env python
"""grain-merge is a tool add ensure a grain value is uniquely
added to a grain list.
"""
__license__ = """\
Copyright (c) 2013 Wikimedia Foundation <info@wikimedia.org>

Permission to use, copy, modify, and distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.\
"""

import sys
import salt.client

def main(argv):
    if len(argv) != 3:
        sys.stderr.write('Usage: grain-merge <grain> <value>\r\n')
        return 1
    grain = argv[1]
    value = [argv[2]]
    caller = salt.client.Caller()
    grain_ret = caller.function('grains.get', grain)
    if grain_ret and isinstance(grain_ret, list):
        caller.function('grains.setval', grain, list(set(grain_ret + value)))
    else:
        caller.function('grains.setval', grain, value)
    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv))
