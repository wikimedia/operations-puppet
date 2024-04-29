# SPDX-License-Identifier: Apache-2.0
# Class: role::cephadm::storage
#
# Sets up a Ceph storage server to be managed by cephadm. Currently
# this involves osd/mon/mgr daemons.
#
class role::cephadm::storage {
    system::role { 'cephadm::storage':
        description => 'Cephadm-managed storage server',
    }

    include profile::base::production
    include profile::firewall
    include profile::cephadm::target
    include profile::cephadm::storage
}
