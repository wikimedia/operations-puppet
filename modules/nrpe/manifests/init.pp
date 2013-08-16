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
                'nagios-plugins-standard' ]:
        ensure => present,
    }

    if $allowed_hosts == undef {
        $nrpe_allowed_hosts = $::realm ? {
            'production' => '127.0.0.1,208.80.152.185,208.80.152.161,208.80.154.14',
            'labs'       => '10.4.0.120',
            default      => '127.0.0.1',
        }
    } else {
        $nrpe_allowed_hosts = $allowed_hosts
    }

    file { '/etc/nagios/nrpe_local.cfg':
        ensure  => present,
        owner   => root,
        group   => root,
        mode    => '0444',
        content => template('nrpe/nrpe_local.cfg.erb'),
        require => Package['nagios-nrpe-server'],
        notify  => Service['nagios-nrpe-server'],
    }

    # TODO: Remove this after the file has been purged everywhere
    file { '/usr/lib/nagios/plugins/check_dpkg':
        ensure  => absent,
    }

    # Have a directory with all our plugins.
    file { '/usr/local/lib/nagios/plugins/':
        ensure  => directory,
        owner   => root,
        group   => root,
        mode    => '0444',
        recurse => true,
        purge   => true,
        force   => true,
        source  => 'puppet:///modules/nrpe/plugins',
    }

    service { 'nagios-nrpe-server':
        ensure  => running,
        require => Package['nagios-nrpe-server'],
    }

    #Collect virtual NRPE nagios service checks
    Monitor_service <| tag == 'nrpe' |>
}
