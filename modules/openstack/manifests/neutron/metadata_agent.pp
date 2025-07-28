class openstack::neutron::metadata_agent(
    $version,
    Stdlib::Fqdn $keystone_api_fqdn,
    $metadata_proxy_shared_secret,
    $report_interval,
    Integer[1] $nofile = 67107840,
    ) {

    class { "openstack::neutron::metadata_agent::${version}":
        keystone_api_fqdn            => $keystone_api_fqdn,
        metadata_proxy_shared_secret => $metadata_proxy_shared_secret,
        report_interval              => $report_interval,
    }

    systemd::service { 'neutron-metadata-agent':
        ensure             => 'present',
        content            => "[Service]\nLimitNOFILE = ${nofile}",
        override           => true,
        monitoring_enabled => false,  # we have our own
        service_params     => {
            ensure    => 'running',
            subscribe => [
                File['/etc/neutron/neutron.conf'],
                File['/etc/neutron/metadata_agent.ini'],
            ],
            require   => Package['neutron-metadata-agent'],
        },
    }
}
