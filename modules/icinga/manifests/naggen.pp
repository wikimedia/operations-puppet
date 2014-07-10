class icinga::naggen {

    # Naggen takes exported resources from hosts and creates nagios
    # configuration files

    require icinga::packages

    file { '/etc/icinga/puppet_hosts.cfg':
        content => generate('/usr/local/bin/naggen2', '--type', 'hosts'),
        backup  => false,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
    }
    file { '/etc/icinga/puppet_services.cfg':
        content => generate('/usr/local/bin/naggen2', '--type', 'services'),
        backup  => false,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
    }
    file { '/etc/icinga/puppet_hostextinfo.cfg':
        content => generate('/usr/local/bin/naggen2', '--type', 'hostextinfo'),
        backup  => false,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
    }

    # Fix permissions

    file { $icinga::monitor::configuration::variables::puppet_files:
        ensure => present,
        mode   => '0644',
    }

    # Collect all (virtual) resources
    Monitor_group <| |> {
        notify => Service[icinga],
    }
    Monitor_host <| |> {
        notify => Service[icinga],
    }
    Monitor_service <| tag != 'nrpe' |> {
        notify => Service[icinga],
    }

}

