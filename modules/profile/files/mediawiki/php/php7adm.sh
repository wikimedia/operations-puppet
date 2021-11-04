#!/bin/bash
function usage() {
    cat <<EOF
php7madm -- Shell helper for the PHP7 admin site.

Usage:

   php7adm [ENDPOINT] [--KEY=VALUE ..]

Example:

   php7adm metrics

By default, php7adm will operate on the default php instance. If you
want to operate on another one, please declare the PHP_VERSION variable.

EOF
    exit 2
}
case $1 in --help|-h|help)
  usage
  ;;
esac
# Determine the port we're communicating on.
if [ -n "$PHP_VERSION" ]; then
  ADMIN_PORT=$(jq -r ".\"$PHP_VERSION\"" < /etc/php7adm.versions)
  if [[ "$ADMIN_PORT" == "null" ]]; then
    echo "Unsupported php version '${PHP_VERSION}'"
    exit 1
  fi
else
  ADMIN_PORT=9181
fi

# Remove the leading slash from the cli argument.
url="http://localhost:${ADMIN_PORT}/${1#/}"
shift
params=()
for arg in "${@##--}"; do params+=('--data-urlencode' "$arg"); done
/usr/bin/curl --netrc-file /etc/php7adm.netrc -s -G "${params[@]}" "$url"
