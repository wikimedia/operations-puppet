#!/bin/bash
function usage() {
    cat <<EOF
php7madm -- Shell helper for the PHP7 admin site.

Usage:

   php7adm [ENDPOINT] [--KEY=VALUE ..]

Example:

   php7adm metrics

EOF
    exit 2
}
case $1 in --help|-h|help)
  usage
  ;;
esac
# Remove the leading slash from the cli argument.
url="http://localhost:9181/${1#/}"
shift
params=()
for arg in "${@##--}"; do params+=('--data-urlencode' "$arg"); done
/usr/bin/curl --netrc-file /etc/php7adm.netrc -s -G "${params[@]}" "$url"
