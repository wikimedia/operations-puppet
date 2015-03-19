#!/bin/bash

# Executes update-ocsp.sh for all existing OCSP files,
# continuing through the list even if some fail, and then
# reloads nginx configuration to apply updates and exits
# with a status that reflects whether any updates failed

OCSP_DIR=/var/ssl/ocsp

some_failed=0
for existing in /var/ssl/ocsp/*.ocsp; do
    bn=$(basename $existing)
    certname=${bn%.ocsp}
    /usr/local/sbin/update-ocsp.sh $certname
    if [ $? -ne 0 ]; then
        echo OCSP update failed for $certname
        some_failed=1
    fi
done

service nginx reload

exit $some_failed
