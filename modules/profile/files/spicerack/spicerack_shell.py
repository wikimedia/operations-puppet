#!/usr/bin/python3 -i
# SPDX-License-Identifier: Apache-2.0
_BANNER = """##### SPICERACK INTERACTIVE SHELL #####
#
# This interactive shell allows to test and use specific Spicerack bits in the same way they are
# available inside the Cookbooks.
#
# There is one available object, spicerack, that is an instance of spicerack.Spicerack like the
# one available inside the cookbooks.
# By default the shell will setup Spicerack with DRY-RUN set to True. If --live is passed the
# DRY-RUN flag will be set to False and the instance will actually modify production systems hence
# BE CAREFUL when using it.
# The shell has the default Python's autocompletion and is possible to get help on objects, e.g.:
#
#    help(spicerack)
#
# The Spicerack documentation is available at:
#
#   https://doc.wikimedia.org/spicerack/master/api/index.html
#
# The logging for the Spicerack modules is already set up and will log into:
#
#   {log_path}
#
# Like the cookbooks there are two log files, one at INFO level and the other at DEBUG level.
#
# Example usage:
#
#    >>> hosts = spicerack.remote().query("A:sretest")
#
# DRY-RUN = {dry_run}
#"""


def _main():
    """Initialize the Spicerack instance and return it."""
    # Explicitly importing inside the function to keep a clean locals() for the interactive shell
    import argparse
    import os
    from pathlib import Path

    from wmflib.config import load_yaml_config
    from wmflib.interactive import get_username

    from spicerack import Spicerack
    from spicerack._log import setup_logging

    description = (
        "Interactive Spicerack Shell\n\n"
        "Opens a Python REPL shell with the same spicerack instance available in the cookbooks."
    )

    parser = argparse.ArgumentParser(
        description=description,
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument(
        "--live",
        action="store_true",
        help=("Sets Spicerack with DRY-RUN=False and allow to make live changes to the "
              "production systems. (default: False)"),
    )
    args = parser.parse_args()
    dry_run = not args.live

    if os.geteuid() != 0:
        parser.error("This script must be run with sudo")

    username = get_username()
    user_home = Path(f"/home/{username}")
    if not user_home.exists():
        parser.error(f"Failed to find home directory '{user_home}'.\n"
                     "This script must be run with sudo from your own user.")

    log_path = user_home / "cookbooks_testing" / "logs" / "interactive"
    config = load_yaml_config(Path("/etc/spicerack/config.yaml"))
    setup_logging(
        log_path,
        "interactive",
        username,
        dry_run=dry_run,
        host=config["tcpircbot_host"],
        port=config["tcpircbot_port"],
    )

    params = config.get("instance_params", {})
    params["dry_run"] = dry_run
    spicerack = Spicerack(**params)

    print(_BANNER.format(log_path=log_path, dry_run=spicerack.dry_run))
    return spicerack


if __name__ == "__main__":
    """Initialize a spicerack instance and drop into a REPL shell via the '-i' in the shebang."""
    try:
        spicerack = _main()
    except BaseException as e:  # Exit the interactive shell if the setup failed
        # Explicitly importing inside the except block to keep a clean locals() for the shell
        import os
        import sys
        import traceback

        if isinstance(e, SystemExit) and isinstance(e.code, int):
            # Assuming any message has already been printed out, like argparse
            # Using os._exit() to exit from the interactive shell, the normal exit() or
            # SystemExit won't work
            os._exit(e.code)
        else:
            # Print the traceback of the exception before exiting
            sys.stderr.write("Failed to initialize spicerack-shell:\n")
            traceback.print_exc(file=sys.stderr)
            sys.stderr.flush()
            os._exit(1)
