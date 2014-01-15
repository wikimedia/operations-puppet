class role::etherpad{

    if $::realm == 'labs' {
        $etherpad_host = $fqdn
        $etherpad_ssl_cert = '/etc/ssl/certs/ssl-cert-snakeoil.pem'
        $etherpad_ssl_key = '/etc/ssl/private/ssl-cert-snakeoil.key'
    } else {
        $etherpad_host = 'etherpad.wikimedia.org'
        $etherpad_serveraliases = 'epl.wikimedia.org'
        install_certificate{ "etherpad.wikimedia.org": }
        $etherpad_ssl_cert = '/etc/ssl/certs/etherpad.wikimedia.org.pem'
        $etherpad_ssl_key = '/etc/ssl/private/etherpad.wikimedia.org.key'
    }

    $etherpad_ip = '127.0.0.1'
    $etherpad_port = '9001'

    file { '/etc/apache2/sites-available/etherpad.wikimedia.org':
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        notify  => Service['apache2'],
        content => template('etherpad/etherpad_lite.wikimedia.org.erb'),
    }

    apache_site { 'controller':
        name => 'etherpad.wikimedia.org'
    }
    apache_module { 'rewrite':
        name => 'rewrite'
    }
    apache_module { 'proxy':
        name => 'proxy'
    }
    apache_module { 'proxy_http':
        name => 'proxy_http'
    }
    apache_module { 'ssl':
        name => 'ssl'
    }
}
