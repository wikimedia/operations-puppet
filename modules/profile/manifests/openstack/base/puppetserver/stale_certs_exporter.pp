# SPDX-License-Identifier: Apache-2.0
class profile::openstack::base::puppetserver::stale_certs_exporter () {
    class { 'prometheus::node_openstack_stale_puppet_certs': }
}
