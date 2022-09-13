# SPDX-License-Identifier: Apache-2.0
# == Class: profile::docker::firewall
#
# This is a simple profile class to allow setting up the proper ferm rules for
# docker
class profile::docker::firewall {

    debian::codename::require('buster')
    # Values are from buster and docker.io 18.09.1+dfsg1-7.1+deb10u2
    $filter_chains = 'DOCKER DOCKER-USER DOCKER-ISOLATION-STAGE-1 DOCKER-ISOLATION-STAGE-2 FORWARD'
    $nat_chains = 'DOCKER PREROUTING OUTPUT POSTROUTING'

    ferm::rule { 'docker-filter-preserve':
        prio  => '00',
        chain => "(${filter_chains})",
        rule  => '@preserve;',
    }
    ferm::rule { 'docker-nat-preserve':
        prio  => '00',
        table => 'nat',
        chain => "(${nat_chains})",
        rule  => '@preserve;',
    }
}
