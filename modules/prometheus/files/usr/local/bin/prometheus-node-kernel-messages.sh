#!/bin/bash

# SPDX-License-Identifier: Apache-2.0

set -eu
set -o pipefail

IGNORE_REGEX_FILE="/etc/prometheus-node-kernel-messages-ignore-regex.txt"
outfile="$(realpath "${1:-/var/lib/prometheus/node.d/kernel-messages.prom}")"
tmpoutfile="${outfile}.$$"
function cleanup {
    rm -f "$tmpoutfile"
}
trap cleanup EXIT

if [ "$(id -u)"  != "0" ] ; then
    echo "root required!" >&2
    exit 1
fi

if [[ -r "$IGNORE_REGEX_FILE" ]]; then
    # ignore comment and empty lines, construct grep -Ev pattern from file
    ignore_regex=$(grep -v ^[[:space:]]*# "$IGNORE_REGEX_FILE" | grep -v ^$ | sed ':a;N;$!ba;s/\n/|/g')
    ignore_command="grep -Ev '${ignore_regex}'"
else
    # NOOP
    ignore_command="cat"
fi

# this will also find messages that were logged before the last boot,
# e.g. if a kernel panic caused a server reboot
SINCE="30m ago"

# When all servers are > buster, we can simplify this line:
# * instead of _TRANSPORT=kernel we can use  '--dmesg --boot=all'
# * we can use "-o cat" instead of "-o json", removing the need of jq
messages=$(journalctl --quiet _TRANSPORT=kernel --since "${SINCE}" -o json --output-fields=PRIORITY,MESSAGE |jq --raw-output '.PRIORITY + " " + .MESSAGE' | eval "${ignore_command}")

# For each log message, categorize it.
# Each message can increase only one category, or no category.
keyword_panic=0
keyword_taint=0
keyword_warning=0
priority_emerg=0
priority_alert=0
priority_crit=0
priority_err=0
priority_warning=0

while read -r msg; do

  # Some keywords are important regardless of their priority, e.g. "[ cut here ]"
  # indicates a Kernel Panic but is logged with priority "warning".
  if [[ "$msg" == *"[ cut here ]"* ]]; then
    keyword_panic=$((keyword_panic+1))

  # I'm less fond of searching for "taint" and "warning" because they often
  # include false positives (i.e. messages that include that word but are not a
  # taint or a warning).
  # TODO: evaluate if these filters ever catch a useful message, otherwise they
  # can be removed.
  elif [[ "$msg" == *"taint"* ]]; then
    keyword_taint=$((keyword_taint+1))
  elif [[ "$msg" == *"warning"* ]]; then
    keyword_warning=$((keyword_warning+1))

  # If the message doesn't match a known keyword, we categorize it according to
  # their priority, for priorities "warning" or higher.
  else
    case ${msg:0:1} in
      0)
        priority_emerg=$((priority_emerg+1));;
      1)
        priority_alert=$((priority_alert+1));;
      2)
        priority_crit=$((priority_crit+1));;
      3)
        priority_err=$((priority_err+1));;
      4)
        priority_warning=$((priority_warning+1));;
    esac

  # Messages with lower priorities and without a known keyword are ignored and
  # do not increase any counter.
  fi

done <<< "$messages"

cat <<EOF >"$tmpoutfile"
# HELP kernel_messages Number of kernel errors since ${SINCE}
# TYPE kernel_messages gauge
kernel_messages{category="keyword_panic"} ${keyword_panic}
kernel_messages{category="keyword_taint"} ${keyword_taint}
kernel_messages{category="keyword_warning"} ${keyword_warning}
kernel_messages{category="priority_emerg"} ${priority_emerg}
kernel_messages{category="priority_alert"} ${priority_alert}
kernel_messages{category="priority_crit"} ${priority_crit}
kernel_messages{category="priority_err"} ${priority_err}
kernel_messages{category="priority_warning"} ${priority_warning}
EOF

mv "$tmpoutfile" "$outfile"
chmod a+r "$outfile"
