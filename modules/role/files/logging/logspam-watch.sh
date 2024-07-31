#!/usr/bin/env bash

# This file comes from operations/puppet/modules/role/files/logging/logspam-watch.sh

# Watch error log spam.  See /usr/bin/logspam for log-filtering implementation
# details.

# Various color vars below might not all be used at any given time, so disable
# warnings about unused vars.  This directive only seems to take effect at the
# top of the file, and can't be re-enabled, note that this could mask other
# bugs:
# shellcheck disable=SC2034

set -eu -o pipefail

# shellcheck disable=SC1091
. /etc/profile.d/mw-log.sh

# Define some control characters - see tput(1):

BOLD=$(tput bold); readonly BOLD
UNDERL=$(tput smul); readonly UNDERL
NORMAL=$(tput sgr0); readonly NORMAL

BLACK=$(tput setaf 0); readonly BLACK
RED=$(tput setaf 1); readonly RED
GREEN=$(tput setaf 2); readonly GREEN
YELLOW=$(tput setaf 3); readonly YELLOW
BLUE=$(tput setaf 4); readonly BLUE
MAGENTA=$(tput setaf 5); readonly MAGENTA
CYAN=$(tput setaf 6); readonly CYAN
WHITE=$(tput setaf 7); readonly WHITE
WHITE_BG=$(tput setab 7); readonly WHITE_BG

COLUMN_LABELS=(
  [1]="count"
  [2]="histo"
  [3]="first"
  [4]="last"
  [5]="ver"
  [6]="exception          "
  [7]="message"
)

MINIMUM_HITS=1
LOGSPAM_WINDOW=60 # Minutes
SHOW_JUNK=0

# shellcheck disable=SC1090
if [ -r ~/.logspamwatchrc ]; then
  . ~/.logspamwatchrc
fi

# Our "view":
function display {
  logspam_output=$(run_logspam)
  distinct_errors="$(echo -n "$logspam_output" | wc -l)"
  total_errors="$(echo -n "$logspam_output" | awk 'BEGIN { s=0 } { s+=$1 } END { print s }')"

  tput clear

  # Current timestamp and status summary:
  titlebar "$( \
    printf '⌚ %s  distinct errors: %d %s  total errors: %d %s '  \
    "$(date '+%H:%M:%S %Z')" \
    "$distinct_errors" \
    "$(get_cat "$distinct_errors")" \
    "$total_errors" \
    "$(get_cat "$total_errors")" \
  )"

  # Print column headers, highlighting the currently-selected sort and bolding
  # column numbers to indicate that they're hotkeys:
  for column in ${!COLUMN_LABELS[*]}; do
    printf '%s%s%s' "$BOLD" "$column" "$NORMAL"
    if [ "$sort_key" == "$column" ]; then
      printf "%s" "$GREEN$UNDERL"
    fi
    printf '%s%s\t' "${COLUMN_LABELS[$column]}" "$NORMAL"
  done

  printf '\n%s\n' "$logspam_output"

  # Pointers to hotkeys and current settings:
  printf '[%sp%sat: %s]' "$BOLD" "$NORMAL" "$GREEN$filter$NORMAL"
  printf ' [%sw%sindow: %s%d%s mins]' "$BOLD" "$NORMAL" "$GREEN" "$LOGSPAM_WINDOW" "$NORMAL"
  printf ' [%sm%sin hits: %s%d%s]' "$BOLD" "$NORMAL" "$GREEN" "$MINIMUM_HITS" "$NORMAL"
  printf ' [%s1234567%s sort]' "$BOLD" "$NORMAL"
  printf ' [%sh%selp]' "$BOLD" "$NORMAL"
  printf ' [%sq%suit]' "$BOLD" "$NORMAL"
  if [ "$SHOW_JUNK" = 1 ]; then
    printf ' [no%sj%sunk] ' "$BOLD" "$NORMAL"
  else
    printf ' [show%sj%sunk] ' "$BOLD" "$NORMAL"
  fi
}

function run_logspam {
  local junk_option=""

  if [ "$SHOW_JUNK" = 1 ]; then
    junk_option="--junk"
  fi

  # shellcheck disable=SC2086
  logspam $junk_option --window "$LOGSPAM_WINDOW" --minimum-hits "$MINIMUM_HITS" "$filter" | \
    sort $sort_dir $sort_type -t$'\t' -k "$sort_key" | \
    (head -n "$(listing_height)"; cat >/dev/null)
}

# Get a height for the error listing that accounts for the current height of
# the terminal and leaves space for column & filter indicators:
function listing_height {
  local lines
  lines="$(tput lines)"
  printf "%d" $((lines - 4))
}

function flip_sort {
  if [ "$sort_dir" == '-r' ]; then
    sort_dir=''
  else
    sort_dir='-r'
  fi
}

function titlebar {
  # Text written into the horizontal rule, left justified:
  text=${1:-}
  length=${#text}

  # Set color, print message:
  printf '%s%s' "$WHITE_BG$BLACK" "$text"

  # Finish the line across the console.  fudge here is because I think length
  # is operating on bytes rather than characters, and we've jammed 3 emoji
  # in here so we get a too-long titlebar otherwise.  (I'm slightly fuzzy on
  # this, but it seems to work in practice for the moment.)
  tput_cols=$(tput cols)
  fudge=3
  cols=$((tput_cols - length - fudge))
  printf "%${cols}s"

  # Clear the background color and start a new line
  printf '%s\n' "$NORMAL"
}

# Get a status indicator for a given count of errors:
function get_cat {
  count="$1"

  if ((count <= 4)); then
    printf '😎'
  elif ((count <= 6)); then
    printf '🦊'
  elif ((count <= 10)); then
    printf '😐'
  elif ((count <= 20)); then
    printf '😑'
  elif ((count <= 700)); then
    printf '😾'
  elif ((count <= 1000)); then
    printf '😿'
  elif ((count <= 5000)); then
    printf '😱'
  else
    printf '☠️'
  fi
}

function helptext {
  tput clear
  titlebar "logspam-watch help"
  cat <<HELPTEXT
logspam-watch is a wrapper around the logspam command.

Glyphs in the "first" and "last" columns indicate the recency of the event:

  ◦ means seen less than 10 minutes ago
  ○ means seen < 5 min ago
  ◍ means seen < 2.5 min ago
  ● means seen < 1 min ago

Keys:

  p:   set a Perl regular expression to match
  w:   set a time window to view in minutes
  m:   set a minimm error threshold
  1-6: sort on a column, or invert existing sort
  h:   read this help page
  q:   quit
  j:   toggle display of "junk" log entries (errors that are almost always present)

HELPTEXT

  read -n 1 -s -r -p "Press a key to continue"
}

# State variables:
sort_key=1
sort_type='-n'
sort_dir='-r'
filter='.*'

# Control loop - poll using read every "tick" and update display:
readonly MAXTICKS=10
readonly TICK_LEN=1
quit=""
ticks="$MAXTICKS"

# Force a redraw when terminal is resizing. Cleans up UI glitches
# much faster after a resize:
trap 'ticks=$MAXTICKS' SIGWINCH

while [ -z "$quit" ]; do
  if ((ticks >= MAXTICKS)); then
    ticks=0
    echo -n '[⌚ Refreshing...] '
    display
  fi

  ((++ticks))

  # Silently (-s) read 1 character of input (-n1) with a timeout of $TICK_LEN
  # seconds (-t$TICK_LEN), and don't error out if nothing is read:
  read -s -r -n1 -t$TICK_LEN input || true

  if [ -n "$input" ]; then
    case "$input" in
      [1234567])
        # If we're already sorting on this column, flip the direction:
        if [ "$input" == "$sort_key" ]; then
          flip_sort
        fi

        # Numeric by default, alpha for exception class and error message:
        sort_type='-n'
        if [ "$input" == '4' ] || [ "$input" == '5' ]; then
          sort_type=''
        fi

        sort_key="$input"
        ticks="$MAXTICKS"
        ;;

      [pgf/])
        printf '\n'
        read -r -p 'new pattern (perl regex): ' -ei "$filter" filter
        if [ -z "$filter" ]; then
          filter='.*'
        fi
        ticks="$MAXTICKS"
        ;;

      w)
        echo
        read -r -p "Time window (minutes, 0 to disable): " -e LOGSPAM_WINDOW
        if [ -z "$LOGSPAM_WINDOW" ]; then
            LOGSPAM_WINDOW=0
        fi
        ticks="$MAXTICKS"
        ;;

      m)
        echo
        read -r -p "Minimum hits: " -e MINIMUM_HITS
        if [ -z "$MINIMUM_HITS" ]; then
            MINIMUM_HITS=1
        fi
        ticks="$MAXTICKS"
        ;;

      j)
        SHOW_JUNK=$(( SHOW_JUNK ^ 1))
        ticks="$MAXTICKS"
        ;;

      [hH?])
        helptext
        ticks="$MAXTICKS"
        ;;

      [qQ])
        quit="yep"
        ;;
    esac
  fi
done

echo
exit 0
