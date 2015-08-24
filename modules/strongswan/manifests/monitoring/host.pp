class strongswan::monitoring::host {
    file { '/usr/local/lib/nagios/plugins/check_strongswan':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/strongswan/monitoring/check_strongswan';
    }

    sudo::user { 'nagios_strongswan':
        user         => 'nagios',
        privileges   => [
                        'ALL = NOPASSWD: /usr/local/lib/nagios/plugins/check_strongswan',
                        ],
    }

# Temporarily disabled around a nasty transition, to avoid spam: https://phabricator.wikimedia.org/T110065
#    nrpe::monitor_service { 'IPsec':
#        description  => 'IPsec',
#        nrpe_command => '/usr/bin/sudo /usr/local/lib/nagios/plugins/check_strongswan',
#    }
}
