# = Class: icinga::naggen
#
# Runs naggen2 to generate hosts, service and hostext config
# from exported puppet resources
class icinga::naggen {
    include ::icinga
    $dbarg = $::use_puppetdb ? {
        true    => '--puppetdb',
        default => '--activerecord',
    }

    file { '/etc/icinga/puppet_hosts.cfg':
        content => generate(
            '/usr/local/bin/naggen2', $dbarg, '--type', 'hosts'),
        backup  => false,
        owner   => 'icinga',
        group   => 'icinga',
        mode    => '0644',
        notify  => Service['icinga'],
    }
    file { '/etc/icinga/puppet_services.cfg':
        content => generate(
            '/usr/local/bin/naggen2', $dbarg, '--type', 'services'),
        backup  => false,
        owner   => 'icinga',
        group   => 'icinga',
        mode    => '0644',
        notify  => Service['icinga'],
    }
    # Collect all (virtual) resources
    Monitoring::Group <| |> {
        notify  => Service['icinga'],
    }
    Monitoring::Host <| |> {
        notify  => Service['icinga'],
    }
    Monitoring::Service <| tag != 'nrpe' |> {
        notify  => Service['icinga'],
    }

}
