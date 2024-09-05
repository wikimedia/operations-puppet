# SPDX-License-Identifier: Apache-2.0
# Class: role::ceph::server
#
# Sets up a Ceph server with co-located services
#
# Note: This role supports the installation of the new Ceph
# cluster being undertaken principally by the Data Engineering
# team in #T324660
#
# Initially comprising five hosts, all Ceph services (osd, mon,
# radosgw, mds) will be running on the same hosts. At a later
# date we may split out these functions and use dedicated
# hardware for specific roles. That is the reason for the
# generic naming of this role.
#
class role::ceph::server {
    system::role { 'ceph::server':
        description => 'Ceph server',
    }

    include profile::base::production
    include profile::firewall
    include profile::ceph::auth::load_all
    include profile::ceph::core
    include profile::ceph::mon
    include profile::ceph::osds
    include profile::ceph::radosgw
    include profile::tlsproxy::envoy
    include profile::bird::anycast
}
