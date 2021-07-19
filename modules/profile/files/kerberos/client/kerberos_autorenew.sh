#!/bin/sh

# If a valid kerberos ticket is found in the credential cache of the user,
# then renew it with krenew. Otherwise the user is warned to execute kinit.
if /usr/bin/klist -s; then
    echo -e '\nRenewing existing Kerberos ticket in the credential cache:'
    /usr/bin/krenew -v
else
    echo -e '\nYou do not have a valid Kerberos ticket in the credential cache, remember to kinit.'
fi
