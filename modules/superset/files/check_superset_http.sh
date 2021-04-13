#!/bin/bash
#
# Check that the superset python server accept the user specified in the header and logs in.
# This will 302 redirect to /superset/welcome, so we use the --location flag to follow redirects.

user_header="$1"
url='http://localhost:9080/login/'
curl --silent --location --max-time 10 --header "${user_header}: admin" $url -c cookiejar-$RANDOM > /dev/null
exitval=$?

if [ $exitval -ne 0 ]; then
    echo "CRITICAL: Superset did not respond to http request successfully"
    exit 2
else
    echo "OK: Superset responded to http request"
    exit 0
fi
