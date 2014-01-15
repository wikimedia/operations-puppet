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
        enable    => true,
        require   => Package['etherpad-lite'],
        subscribe => File['/etc/etherpad-lite/settings.json'],
    }

    file { '/etc/etherpad-lite/settings.json':
        require => Package['etherpad-lite'],
        content => template('etherpad/settings.json.erb'),
    }
    @webserver::apache::module { [ 'proxy', 'rewrite', 'proxy_http' ]:}
    @webserver::apache::site { $etherpad_host:
        ssl      => 'true',
        aliases  => ['epl.wikimedia.org'],
        includes => ['etherpad_proxy.conf'],
    }

    file { '/etc/apache2/etherpad_proxy.conf':
        ensure   => 'present',
        owner    => 'root',
        group    => 'root',
        mode     => '0555',
        content  => template('etherpad/etherpad_proxy.conf.erb'),
        require  => Webserver::Apache::Site[$etherpad_host],
    }
}

