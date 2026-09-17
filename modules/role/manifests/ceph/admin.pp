# SPDX-License-Identifier: Apache-2.0
# Class: role::ceph::admin
#
# Sets up a Ceph administration host for the Data Platform Ceph clusters.
#
# This is a small VM, one in each core data centre. It is the only place
# from which SREs make administrative changes to the RADOS Gateway.
# It receives a minimal ceph.conf and the cluster administrative keyring,
# so radosgw-admin can talk to the local cluster.
#
# See #T435608
#
class role::ceph::admin {
    include profile::base::production
    include profile::firewall
    include profile::ceph::client
}
