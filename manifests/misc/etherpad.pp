# Etherpad

class misc::etherpad_lite {

    include passwords::etherpad_lite

    $etherpad_db_user = $passwords::etherpad_lite::etherpad_db_user
    $etherpad_db_host = $passwords::etherpad_lite::etherpad_db_host
    $etherpad_db_name = $passwords::etherpad_lite::etherpad_db_name
    $etherpad_db_pass = $passwords::etherpad_lite::etherpad_db_pass

    if $::realm == 'labs' {
        $etherpad_host = $fqdn
        $etherpad_ssl_cert = '/etc/ssl/certs/ssl-cert-snakeoil.pem'
        $etherpad_ssl_key = '/etc/ssl/private/ssl-cert-snakeoil.key'
    } else {
        $etherpad_host = 'etherpad.wikimedia.org'
        $etherpad_serveraliases = 'epl.wikimedia.org'
        install_certificate{ 'etherpad.wikimedia.org': ca => 'RapidSSL_CA.pem' }
        $etherpad_ssl_cert = '/etc/ssl/certs/etherpad.wikimedia.org.pem'
        $etherpad_ssl_key = '/etc/ssl/private/etherpad.wikimedia.org.key'
    }

    $etherpad_ip = '127.0.0.1'
    $etherpad_port = '9001'

    system::role { 'misc::etherpad_lite': description => 'Etherpad-lite server' }

    file {
        '/etc/apache2/sites-enabled/etherpad.wikimedia.org':
            ensure  => present,
            mode    => '0444',
            owner   => 'root',
            group   => 'root',
            notify  => Service['apache2'],
            content => template('apache/sites/etherpad_lite.wikimedia.org.erb'),
    }
    file {
        '/usr/share/etherpad-lite/src/static/robots.txt':
            ensure  => present,
            mode    => '0444',
            owner   => 'root',
            group   => 'root',
            source  => 'puppet:///files/misc/etherpad-robots.txt',
    }


    # FIX ME - move this to a common role to avoid duplicate defs
    include ::apache::mod::rewrite
    include ::apache::mod::proxy
    include ::apache::mod::proxy_http
    include ::apache::mod::ssl

    package { 'etherpad-lite':
        ensure => latest;
    }
    service { 'etherpad-lite':
        ensure    => running,
        require   => Package['etherpad-lite'],
        subscribe => File['/etc/etherpad-lite/settings.json'],
        enable    => true;
    }

    # Icinga process monitoring, RT #5790
    monitor_service { 'etherpad-lite-proc':
        description   => 'etherpad_lite_process_running',
        check_command => 'nrpe_check_etherpad_lite';
    }

    monitor_service { 'etherpad-lite-http':
        description   => 'etherpad.wikimedia.org',
        check_command => 'check_http_url!etherpad.wikimedia.org!/',
    }

    monitor_service { 'etherpad-lite-https':
        description   => 'https.etherpad.wikimedia.org',
        check_command => 'check_https_url_for_string!etherpad.wikimedia.org!/p/Etherpad!\'<title>Etherpad\'',
    }




    #FIXME
    #service { apache2:
    #   enable => true,
    #   ensure => running;
    #}

    file {
        '/etc/etherpad-lite/settings.json':
            require => Package['etherpad-lite'],
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            content => template('etherpad_lite/settings.json.erb');
    }

    ferm::service { 'etherpad_http':
        proto   => 'tcp',
        port    => '80',
    }

    ferm::service { 'etherpad_https':
        proto   => 'tcp',
        port    => '443',
    }


}

