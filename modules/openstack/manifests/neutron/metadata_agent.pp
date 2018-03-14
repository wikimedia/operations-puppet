class openstack::neutron::metadata_agent(
    $version,
    $metadata_proxy_shared_secret,
    ) {

    package {'neutron-metadata-agent':
        ensure => 'present',
    }

    file { '/etc/neutron/metadata_agent.ini':
        content => template("openstack/${version}/neutron/metadata_agent.ini.erb"),
        owner   => 'neutron',
        group   => 'neutron',
        mode    => '0440',
        require => Package['neutron-metadata-agent'];
    }
}
