# SPDX-License-Identifier: Apache-2.0
# Class: role::cephadm::controller
#
# Sets up a Ceph storage server that is also the cluster node with
# cephadm on (and thus is the controller of a Ceph cluster.
#
class role::cephadm::controller {
    system::role { 'cephadm::controller':
        description => 'Cephadm controller node',
    }

    include profile::base::production
    include profile::firewall
    include profile::cephadm::target
    # Needed so we can find hosts' rack locations
    include profile::netbox::data
    include profile::cephadm::controller
    include profile::cephadm::storage
}
