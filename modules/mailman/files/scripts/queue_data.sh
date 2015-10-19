#!/bin/bash
# dump mailman queue data to HTML table
# by dzahn, as requested by johnlewis
#
# usage:
# -i (i)nitialize file - run this once to setup the HTML file
# -a (a)ppend data row - run this in a cron job to append rows
# -f (f)ooter - run this once when done for valid HTML to close the file
#
# example:
# queue_data -i > /var/www/qdata.html
# queue_data -a >> /var/www/qdata.html
# queue_data -a >> /var/www/qdata.html
# ..
# queue_data -f >> /var/www/qdata.html
#
# will create a valid file

qdir="/var/lib/mailman/qfiles"
myqueues=$(ls ${qdir})

dochead="<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">\n<html xmlns=\"http://www.w3.org/1999/xhtml\" lang=\"en\" xml:lang=\"en\">"

htmlhead="<head>\n<title>mailman queue data</title>\n</head>\n<body>\n<h2>mailman queue data</h2>\n<table border=\"1\">\n<tr>\n<th>timestamp</th>"

htmlfoot="</table>\n</body>\n</html>\n"

case "$1" in

-i)

    echo -e "${dochead}\n${htmlhead}"
    for myq in $myqueues; do
        echo "<th>${myq}</th>"
    done
    echo -e "</tr>\n"

;;

-a)

timestamp=$(date +"%Y-%m-%d-%H:%m:%S")
echo "<tr><td>${timestamp}</td>"

for myq in $myqueues; do

    numfiles=$(find ${qdir}/${myq} | wc -l)

    echo "<td>${numfiles}</td>"

done

echo "</tr>"

;;

-f)

    echo -e "</table></body></html>\n"

;;

*)

echo -e "\nHi ${USER},\n\nThis script creates a HTML table with mailman queue data.
\n\nusage:\n-i (i)nitialize file\n-a (a)ppend data row,\n-f add (f)ooter\n\n
On first run use -i to create the HTML header,\nthen put it into a cronjob with -a to append data rows,
\nand when done run -f for a valid HTML footer.\n\nkthxbye. cya\n"
;;

esac

