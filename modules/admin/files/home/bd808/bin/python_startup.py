# -*- coding: utf-8 -*-
# Python shell startup file based on
# https://github.com/jbisbee/python-shell-enhancement
#
# Copyright (c) 2013 Jeff Bisbee
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.

try:
    import readline
    import rlcompleter
    import atexit
    import os
    import sys
    import platform
except ImportError as exception:
    pass
else:
    # Enable Tab Completion
    readline.parse_and_bind("tab: complete")

    # Enable History File
    history_file = os.environ.get("PYTHON_HISTORY_FILE",
            os.path.join(os.environ['HOME'], '.pythonhistory'))

    if os.path.isfile(history_file):
        readline.read_history_file(history_file)
    else:
        open(history_file, 'a').close()

    atexit.register(readline.write_history_file, history_file)
