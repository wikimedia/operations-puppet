# SPDX-License-Identifier: Apache-2.0
class profile::openstack::base::neutron::metadata_agent(
    $version = lookup('profile::openstack::base::version'),
    Stdlib::Fqdn $keystone_api_fqdn = lookup('profile::openstack::base::keystone_api_fqdn'),
    $metadata_proxy_shared_secret = lookup('profile::openstack::base::neutron::metadata_proxy_shared_secret'),
    $report_interval = lookup('profile::openstack::base::neutron::report_interval'),
    ) {

    class {'::openstack::neutron::metadata_agent':
        version                      => $version,
        keystone_api_fqdn            => $keystone_api_fqdn,
        metadata_proxy_shared_secret => $metadata_proxy_shared_secret,
        report_interval              => $report_interval,
    }
    contain '::openstack::neutron::metadata_agent'
}
