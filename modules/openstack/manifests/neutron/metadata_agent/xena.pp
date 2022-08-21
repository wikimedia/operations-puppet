# SPDX-License-Identifier: Apache-2.0

class openstack::neutron::metadata_agent::xena(
    Stdlib::Fqdn $keystone_api_fqdn,
    $metadata_proxy_shared_secret,
    $report_interval,
){
    class { "openstack::neutron::metadata_agent::xena::${::lsbdistcodename}": }

    file { '/etc/neutron/metadata_agent.ini':
        content => template('openstack/xena/neutron/metadata_agent.ini.erb'),
        owner   => 'neutron',
        group   => 'neutron',
        mode    => '0640',
        require => Package['neutron-metadata-agent'];
    }
}
