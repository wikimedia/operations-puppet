#!/usr/bin/env bash
# Apply vagrant puppet configuration to this host.

VAGRANT_HOME=/vagrant
PUPPET_HOME=${VAGRANT_HOME}/puppet
MANIFEST=${PUPPET_HOME}/manifests/site.pp

exec puppet apply \
    --modulepath ${PUPPET_HOME}/modules \
    --manifestdir ${PUPPET_HOME}/manifests \
    --templatedir ${PUPPET_HOME}/templates \
    --verbose \
    --logdest ${VAGRANT_HOME}/logs/puppet/puppet-$(date +%Y%m%dT%H%M).log \
    --logdest console \
    --detailed-exitcodes \
    ${MANIFEST}
