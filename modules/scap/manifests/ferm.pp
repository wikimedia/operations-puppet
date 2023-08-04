# SPDX-License-Identifier: Apache-2.0
# == Class scap::ferm
# Allows ssh access from $DEPLOYMENT_HOSTS
#
class scap::ferm(Wmflib::Ensure $ensure = 'present') {
    # allow ssh from deployment hosts
    firewall::service { 'deployment-ssh':
        ensure   => $ensure,
        proto    => 'tcp',
        port     => 22,
        src_sets => ['DEPLOYMENT_HOSTS'],
    }
}
