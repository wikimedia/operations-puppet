# SPDX-License-Identifier: Apache-2.0
# ferm firewall rules for docker
class profile::docker::ferm {

    # Ship the entire docker iptables configuration via ferm
    # This is here to make sure docker and ferm play nice together.
    # For now we only want this on a subset of hosts, which is why we don't put it in
    # profile::docker::engine. This relies on settings iptables: false in docker
    ferm::conf { 'docker-ferm':
        ensure => present,
        prio   => 20,
        source => 'puppet:///modules/profile/docker/docker-ferm',
    }
}
