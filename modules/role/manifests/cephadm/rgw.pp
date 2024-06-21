# SPDX-License-Identifier: Apache-2.0
# Class: role::cephadm::rgw
#
# Sets up a gateway node (i.e. a provider of S3 and maybe swift API
# access to) for a cephadm-controlled Ceph cluster.
#
class role::cephadm::rgw {
    system::role { 'cephadm::rgw':
        description => 'Cephadm-managed RGW node',
    }

    include profile::base::production
    include profile::firewall

    include profile::lvs::realserver

    include profile::tlsproxy::envoy

    include profile::cephadm::target
    include profile::cephadm::rgw
}
