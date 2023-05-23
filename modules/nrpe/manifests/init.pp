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
                'monitoring-plugins',
                'monitoring-plugins-basic',
                'monitoring-plugins-standard',
            ]:
        ensure => present,
    }

    $nrpe_local_data = {
        server_address => $facts['wmflib']['is_container'] ? {
            true  => '0.0.0.0',
            false => $facts['networking']['ip'],
        },
        allowed_hosts  => $allowed_hosts,
    }
    file { '/etc/nagios/nrpe_local.cfg':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => epp('nrpe/nrpe_local.cfg.epp', $nrpe_local_data),
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
        require => File['/usr/local/lib/nagios/'],
    }

    base::service_unit { 'nagios-nrpe-server':
        systemd => systemd_template('nagios-nrpe-server'),
        require => Package['nagios-nrpe-server'],
    }

    profile::auto_restarts::service { 'nagios-nrpe-server': }

    #Collect virtual nrpe checks
    File <| tag == 'nrpe::check' |> {
        require => Package['nagios-nrpe-server'],
    }

    Sudo::User <| tag == 'nrpe::check' |>

    File <| tag == 'nrpe::plugin' |> {
        require => File['/usr/local/lib/nagios/plugins/'],
    }
}
