# SPDX-License-Identifier: Apache-2.0
# Class: role::ceph::caphadm
#
# Sets up a server with cephadm and the configuration
# required to perform management of Ceph clusters
#
class role::ceph::cephadm {
    system::role { 'ceph::cephadm':
        description => 'Ceph cluster admin and orchestration server',
    }

    include profile::base::production
    include profile::firewall
}
