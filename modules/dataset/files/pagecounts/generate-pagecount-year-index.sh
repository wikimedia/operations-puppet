#!/bin/bash

# Generate index.html file for one year of pagecount/projectcount
# files.
# Run this from within the directory for a given year; it should
# contain one subdirectory per month.  These subdirs should have
# the form 2011-01, 2011-02 etc.

dir=`pwd`
year=`basename "$dir"`
yearmonths=`ls -d 2[0-9][0-9][0-9]-[0-9][0-9] 2>/dev/null`

echo '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">
<html>
  <head>
    <title>Index of page view statistics for '"$year"'</title>
  </head>
  <body bgcolor="#ffffff">
  <h1>Index of page view statistics for '"$year"'</h1>' > index.html

if [ ! -z "$yearmonths" ]; then
    echo "  <h2>Pagecount files for $year</h2>" >> index.html
    echo "  <p><ul>" >> index.html
    for ym in $yearmonths; do
        echo "  <li><a href=\"$ym\">$ym</a></li>" >> index.html
    done
    echo "  </ul></p>" >> index.html
fi

echo '
  <hr />
  <p><a href="../">Return to page view statistics main page</a></p>
  </body>
</html>
' >> index.html

chmod 644 index.html
