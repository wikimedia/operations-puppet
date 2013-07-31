# Class: nrpe::packages
#
# Install and configure nrpe package
#
# Parameters:
#
# Actions:
#   Install rnpe package
#   Configure nrpe
#
# Requires:
#
# Sample Usage:
#   include nrpe::packages

class nrpe::packages {
    # TODO: Parameterize this.
    $nrpe_allowed_hosts = $::realm ? {
        'production' => '127.0.0.1,208.80.152.185,208.80.152.161,208.80.154.14',
        'labs'       => '10.4.0.120',
        default      => '127.0.0.1',
    }

    package { [ 'nagios-nrpe-server',
                'nagios-plugins',
                'nagios-plugins-basic',
                'nagios-plugins-extra',
                'nagios-plugins-standard',
                'libssl0.9.8' ]:
        ensure => present,
    }

    file { '/etc/nagios/nrpe_local.cfg':
        ensure  => present,
        owner   => root,
        group   => root,
        mode    => '0444',
        content => template('nrpe/nrpe_local.cfg.erb'),
        require => Package[nagios-nrpe-server],
    }

    # TODO: Move this somewhere else
    file { '/usr/lib/nagios/plugins/check_dpkg':
        ensure  => present,
        owner   => root,
        group   => root,
        mode    => '0555',
        source  => 'puppet:///modules/nrpe/check_dpkg',
    }
}
