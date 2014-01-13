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
        install_certificate{ "etherpad.wikimedia.org": }
        $etherpad_ssl_cert = '/etc/ssl/certs/etherpad.wikimedia.org.pem'
        $etherpad_ssl_key = '/etc/ssl/private/etherpad.wikimedia.org.key'
    }

    $etherpad_ip = '127.0.0.1'
    $etherpad_port = '9001'

    system::role { 'misc::etherpad_lite': description => 'Etherpad-lite server' }

    file {
        '/etc/apache2/sites-available/etherpad.wikimedia.org':
            ensure  => present,
            mode    => '0444',
            owner   => 'root',
            group   => 'root',
            notify  => Service['apache2'],
            content => template('apache/sites/etherpad_lite.wikimedia.org.erb'),
    }

    apache_site { 'controller': name => 'etherpad.wikimedia.org' }
    # FIX ME - move this to a common role to avoid duplicate defs
    # apache_module { rewrite: name => 'rewrite' }
    apache_module { 'proxy': name => 'proxy' }
    apache_module { 'proxy_http': name => 'proxy_http' }
    # apache_module { ssl: name => 'ssl' }

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
}

