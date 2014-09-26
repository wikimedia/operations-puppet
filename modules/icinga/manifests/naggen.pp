# = Class: icinga::naggen
#
# Runs naggen2 to generate hosts, service and hostext config
# from exported puppet resources
class icinga::naggen {
    include icinga

    file { '/etc/icinga/puppet_hosts.cfg':
        content => generate('/usr/local/bin/naggen2', '--type', 'hosts'),
        backup  => false,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        notify  => Service['icinga'],
    }
    file { '/etc/icinga/puppet_services.cfg':
        content => generate('/usr/local/bin/naggen2', '--type', 'services'),
        backup  => false,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        notify  => Service['icinga'],
    }
    file { '/etc/icinga/puppet_hostextinfo.cfg':
        content => generate('/usr/local/bin/naggen2', '--type', 'hostextinfo'),
        backup  => false,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        notify  => Service['icinga'],
    }

    # Collect all (virtual) resources
    Monitor_group <| |> {
        notify  => Service['icinga'],
    }
    Monitor_host <| |> {
        notify  => Service['icinga'],
    }
    Monitor_service <| tag != 'nrpe' |> {
        notify  => Service['icinga'],
    }

}
