# -*- coding: utf-8 -*-
# Python shell startup file based on
# https://github.com/jbisbee/python-shell-enhancement
#

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
