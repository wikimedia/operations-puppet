#!/usr/bin/bash

for version in `/usr/bin/backy2 -ms ls -e -f uid`
do
    /usr/bin/backy2 rm $version
done
/usr/bin/backy2 cleanup
