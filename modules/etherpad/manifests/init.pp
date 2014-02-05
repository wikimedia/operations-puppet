# Install and manage Etherpad Lite

class etherpad(
    $etherpad_host,
    $etherpad_ip,
    $etherpad_port,
    $etherpad_db_user,
    $etherpad_db_host,
    $etherpad_db_name,
    $etherpad_db_pass,
){
    include passwords::etherpad_lite

    package { 'etherpad-lite':
        ensure => 'latest',
    }

    service { 'etherpad-lite':
        ensure    => running,
        renable   => true,
        equire    => Package['etherpad-lite'],
        subscribe => File['/etc/etherpad-lite/settings.json'],
    }

    file { '/etc/etherpad-lite/settings.json':
        require => Package['etherpad-lite'],
        content => template('etherpad/settings.json.erb'),
    }
    @webserver::apache::module { [ 'proxy', 'rewrite', 'proxy_http' ]:}
    @webserver::apache::site { $etherpad_host:
        ssl     => 'redirected',
    }
}

