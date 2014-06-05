class webserver::php5(
    $ssl = 'false',
) {

    include webserver::base

    package { ['apache2-mpm-prefork',
            'libapache2-mod-php5' ]:
        ensure => 'present',
    }

    if $ssl == true {
        apache_module { 'ssl':
            name => 'ssl' }
    }

    service { 'apache2':
        ensure    => running,
        require   => Package['apache2-mpm-prefork'],
        subscribe => Package['libapache2-mod-php5'],
    }

    # ensure default site is removed
    apache_site { '000-default':
        ensure => 'absent',
        name   => '000-default',
    }

    apache_site { '000-default-ssl':
        ensure => 'absent',
        name   => '000-default-ssl',
    }

    # Monitoring
    monitor_service { 'http':
        description   => 'HTTP',
        check_command => 'check_http',
    }
}
