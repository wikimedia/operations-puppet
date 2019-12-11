#!/bin/sh

# This can be removed once https://phabricator.wikimedia.org/T214734 is resolved.

cat <<'MOTD'
     _         _   _  ___ _____                    _   _     _
  __| | ___   | \ | |/ _ \_   _|  _   _ ___  ___  | |_| |__ (_)___
/  _` |/ _ \  |  \| | | | || |   | | | / __|/ _ \ | __| '_ \| / __|
| (_| | (_) | | |\  | |_| || |   | |_| \__ \  __/ | |_| | | | \__ \
 \__,_|\___/  |_| \_|\___/ |_|    \__,_|___/\___|  \__|_| |_|_|___/

                              _
 ___  ___ _ ____   _____ _ __| |
/ __|/ _ \ '__\ \ / / _ \ '__| |
\__ \  __/ |   \ V /  __/ |  |_|
|___/\___|_|    \_/ \___|_|  (_)


mwdebug1002 has mysteriously-broken logging infrastructure:
see https://phabricator.wikimedia.org/T214734
Please use another mwdebug host to perform your testing.

MOTD
