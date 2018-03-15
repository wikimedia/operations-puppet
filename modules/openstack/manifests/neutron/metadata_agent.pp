class openstack::neutron::metadata_agent(
    $version,
    $nova_controller,
    $metadata_proxy_shared_secret,
    ) {

    package {'neutron-metadata-agent':
        ensure => 'present',
    }

    file { '/etc/neutron/metadata_agent.ini':
        content => template("openstack/${version}/neutron/metadata_agent.ini.erb"),
        owner   => 'neutron',
        group   => 'neutron',
        mode    => '0640',
        require => Package['neutron-metadata-agent'];
    }

    service {'neutron-metadata-agent':
        ensure  => 'running',
        require => Package['neutron-metadata-agent'],
    }
}
