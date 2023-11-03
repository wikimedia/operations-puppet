# SPDX-License-Identifier: Apache-2.0

class profile::openstack::codfw1dev::metrics (
    Stdlib::Fqdn $active_host = lookup('profile::openstack::codfw1dev::metrics::openstack_exporter_host'),
) {
    class { '::profile::prometheus::openstack_exporter':
        ensure      => ($active_host == $::facts['networking']['fqdn']).bool2str('present', 'absent'),
        listen_port => 12345,
        cloud       => 'codfw1dev',
    }
}
