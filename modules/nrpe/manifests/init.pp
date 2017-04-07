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
#   include ::nrpe
#
class nrpe($allowed_hosts='127.0.0.1') {
    package { [ 'nagios-nrpe-server',
                'nagios-plugins',
                'nagios-plugins-basic',
                'nagios-plugins-standard',
            ]:
        ensure => present,
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
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
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

    #Collect virtual nrpe checks
    File <| tag == 'nrpe::check' |> {
        require => Package['nagios-nrpe-server'],
    }
}
