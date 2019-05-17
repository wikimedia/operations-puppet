class strongswan::monitoring::host {
    file { '/usr/local/lib/nagios/plugins/check_strongswan':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/strongswan/monitoring/check_strongswan';
    }

    sudo::user { 'nagios_strongswan':
        user       => 'nagios',
        privileges => [
                        'ALL = NOPASSWD: /usr/local/lib/nagios/plugins/check_strongswan',
                        ],
    }

    nrpe::monitor_service { 'IPsec':
        description  => 'IPsec',
        nrpe_command => '/usr/bin/sudo /usr/local/lib/nagios/plugins/check_strongswan',
        retries      => 7, # default 3, this is temporary during rolling cache restarts (--bblack 2016-02-05)
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Monitoring/strongswan',
    }
}
