class torrus {
    system::role { 'torrus':
        description => 'Torrus',
    }

    package { 'torrus-common':
            ensure => present,
    }

    exec { 'torrus clearcache':
        command     => '/usr/sbin/torrus clearcache',
        require     => Class['torrus::config'],
        subscribe   => Class['torrus::config'],
        logoutput   => true,
        refreshonly => true,
        before      => Exec['torrus compile'],
    }

    exec { 'torrus compile':
        command     => '/usr/sbin/torrus compile --all',
        require     => Class[['torrus::config',
                            'torrus::xmlconfig']
                        ],
        subscribe   => Class[['torrus::config',
                            'torrus::xmlconfig']
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

    include ::torrus::xmlconfig
    include ::torrus::discovery
}
