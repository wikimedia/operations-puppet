#!/bin/bash -x
#######################################################################
# WARNING: this file is managed by Puppet
# puppet:///files/misc/beta/wmf-beta-parsoid-restart.sh
#######################################################################

if [ "$USER" != 'jenkins-deploy' ]
then
    echo "Script MUST be run as jenkins-deploy user to use its credential"
    exit 1
fi

PARSOID_INSTANCE="deployment-parsoid2.pmtpa.wmflabs"

# The beta autoupdater runs as mwdeploy. We need jenkins-deploy ssh credentials
# to be able to connect to the parsoid instance. On there, we restart Parsoid
# as root.
ssh $PARSOID_INSTANCE \
    sudo -u root /etc/init.d/parsoid $1
