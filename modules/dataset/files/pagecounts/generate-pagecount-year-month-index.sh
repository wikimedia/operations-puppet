#!/bin/bash

# Generate index.html file for one month of pagecount/projectcount
# files.
# Run this from within the directory for a given month; it should
# contain the raw pagecount and projectcount files.  These filenames
# should have a format like pagecounts-yyyymmdd-hhmmss and
# projectcounts-yyyymmdd-hhmmss, for example
# pagecounts-20111107-010000, projectcounts-20111107-010000

dir=`pwd`
yearmonth=`basename "$dir"`
pagecountfiles=`ls pagecount*gz 2>/dev/null`
projectcountfiles=`ls projectcount*[0-9] 2>/dev/null`

echo '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">
<html>
  <head>
    <title>Index of page view statistics for '"$yearmonth"'</title>
  </head>
  <body bgcolor="#ffffff">
  <h1>Index of page view statistics for '"$yearmonth"'</h1>
' > index.html

if [ ! -z "$pagecountfiles" ]; then
    echo "  <h2>Pagecount files for $yearmonth</h2>" >> index.html
    echo "  <p>Check the <a href=\"md5sums.txt\">hashes</a> after your download, to make sure your files arrived intact.</a></p>" >> index.html
    echo "  <p><ul>" >> index.html
    for p in $pagecountfiles; do
        filesize=`ls -sh $p | awk '{ print $1 }'`
        echo "  <li><a href=\"$p\">$p</a>, size $filesize</li>" >> index.html
    done
    echo "  </ul></p>" >> index.html
fi

if [ ! -z "$projectcountfiles" ]; then
    echo "  <h2>Project count files for $yearmonth</h2>" >> index.html
    echo "  <p><ul>" >> index.html
    for p in $projectcountfiles; do
        filesize=`ls -sh $p | awk '{ print $1 }'`
        echo "  <li><a href=\"$p\">$p</a>, size $filesize</li>" >> index.html
    done
    echo "  </ul></p>" >> index.html
fi

echo '
  <hr />
  <p><a href="../">Return to page view statistics for this year</a></p>
  <p><a href="../../">Return to page view statistics main page</a></p>
  </body>
</html>
' >> index.html

chmod 644 index.html
