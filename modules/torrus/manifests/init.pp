class torrus {
    system::role { 'misc::torrus':
        description => 'Torrus',
    }

    package { 'torrus-common':
            ensure => present,
    }

    exec { 'torrus clearcache':
        command     => '/usr/sbin/torrus clearcache',
        require     => Class['misc::torrus::config'],
        subscribe   => Class['misc::torrus::config'],
        logoutput   => true,
        refreshonly => true,
        before      => Exec['torrus compile'],
    }

    exec { 'torrus compile':
        command     => '/usr/sbin/torrus compile --all',
        require     => Class[['misc::torrus::config',
                            'misc::torrus::xmlconfig']
                        ],
        subscribe   => Class[['misc::torrus::config',
                            'misc::torrus::xmlconfig']
                        ],
        logoutput   => true,
        refreshonly => true,
    }

    service { 'torrus-common':
        ensure     => running,
        require    => Exec['torrus compile'],
        subscribe  => File[ ['/etc/torrus/conf/',
                            '/etc/torrus/templates/']
                        ],
        hasrestart => false,
    }

    include torrus::xmlconfig
    include torrus::discovery
}
