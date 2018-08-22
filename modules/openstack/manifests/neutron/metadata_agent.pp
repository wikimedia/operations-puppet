class openstack::neutron::metadata_agent(
    $version,
    $nova_controller,
    $metadata_proxy_shared_secret,
    $report_interval,
    ) {

    if os_version('debian jessie') and ($version == 'mitaka') {
        $install_options = ['-t', 'jessie-backports']
    } else {
        $install_options = ''
    }

    package {'neutron-metadata-agent':
        ensure          => 'present',
        install_options => $install_options,
    }

    file { '/etc/neutron/metadata_agent.ini':
        content => template("openstack/${version}/neutron/metadata_agent.ini.erb"),
        owner   => 'neutron',
        group   => 'neutron',
        mode    => '0640',
        require => Package['neutron-metadata-agent'];
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
