class openstack::neutron::metadata_agent(
    $version,
    Stdlib::Fqdn $keystone_api_fqdn,
    $metadata_proxy_shared_secret,
    $report_interval,
    ) {

    class { "openstack::neutron::metadata_agent::${version}":
        keystone_api_fqdn            => $keystone_api_fqdn,
        metadata_proxy_shared_secret => $metadata_proxy_shared_secret,
        report_interval              => $report_interval,
    }

    service {'neutron-metadata-agent':
        ensure    => 'running',
        require   => Package['neutron-metadata-agent'],
        subscribe => [
                      File['/etc/neutron/neutron.conf'],
                      File['/etc/neutron/metadata_agent.ini'],
            ],
    }
}
