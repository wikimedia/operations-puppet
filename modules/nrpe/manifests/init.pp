# Class: nrpe
#
# This installes nrpe packages, ensures service is running and collects all
# configuration
#
# Parameters:
#
# Actions:
#   Install nrpe packages
#   Manage nrpe service status
#   Collect all needed exported resources
#
# Requires:
#   Definition[monitor_service]
#
# Sample Usage:
#   include nrpe

class nrpe($allowed_hosts=undef) {
    package { [ 'nagios-nrpe-server',
                'nagios-plugins',
                'nagios-plugins-basic',
                'nagios-plugins-extra',
                'nagios-plugins-standard',
            ]:
        ensure => present,
    }

    if $allowed_hosts == undef {
        $nrpe_allowed_hosts = $::realm ? {
            'production' => '127.0.0.1,208.80.152.185,208.80.152.161,208.80.154.14',
            'labs'       => '10.4.1.88',
            default      => '127.0.0.1',
        }
    } else {
        $nrpe_allowed_hosts = $allowed_hosts
    }

    file { '/etc/nagios/nrpe_local.cfg':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('nrpe/nrpe_local.cfg.erb'),
        require => Package['nagios-nrpe-server'],
        notify  => Service['nagios-nrpe-server'],
    }

    file { '/usr/local/lib/nagios/':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    # Have a directory with all our plugins.
    file { '/usr/local/lib/nagios/plugins/':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        recurse => true,
        purge   => true,
        force   => true,
        source  => 'puppet:///modules/nrpe/plugins',
        require => File['/usr/local/lib/nagios/'],
    }

    service { 'nagios-nrpe-server':
        ensure  => running,
        require => Package['nagios-nrpe-server'],
    }

    # firewall nrpe-server, only accept nrpe/5666 from internal
    ferm::rule { 'nrpe_5666':
        rule => 'proto tcp dport 5666 { saddr $INTERNAL ACCEPT; }'
    }

    #Collect virtual nrpe checks
    File <| tag == 'nrpe::check' |> {
        require => Package['nagios-nrpe-server'],
    }
}
