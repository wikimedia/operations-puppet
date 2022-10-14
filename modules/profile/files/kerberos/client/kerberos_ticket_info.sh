#!/bin/sh
# SPDX-License-Identifier: Apache-2.0

# If a valid kerberos ticket is found in the credential cache of the user,
# the output of klist is printed. Otherwise the user is warned to execute kinit.
if /usr/bin/klist -s; then
    echo -e '\nFound a valid Kerberos ticket in the credential cache:'
    /usr/bin/klist
else
    echo -e '\nYou do not have a valid Kerberos ticket in the credential cache, remember to kinit.'
fi