class role::etherpad{

    include passwords::etherpad_lite

    system::role { 'etherpad':
        description => 'Etherpad-lite server'
    }

    $etherpad_ip = '127.0.0.1'
    $etherpad_port = '9001'

    case $::realm {
        'labs': {
            $etherpad_host = $::fqdn
            $etherpad_ssl_cert = '/etc/ssl/certs/ssl-cert-snakeoil.pem'
            $etherpad_ssl_key = '/etc/ssl/private/ssl-cert-snakeoil.key'
        }
        'production': {
            $etherpad_host = 'etherpad.wikimedia.org'
            install_certificate{ 'etherpad.wikimedia.org': }
            $etherpad_ssl_cert = '/etc/ssl/certs/etherpad.wikimedia.org.pem'
            $etherpad_ssl_key = '/etc/ssl/private/etherpad.wikimedia.org.key'
        }
        'default': {
            fail('unknown realm, should be labs or production')
        }
    }

    $ssl_settings = ssl_ciphersuite('apache-2.2', 'compat')

    class { '::etherpad':
        etherpad_host    => $etherpad_host,
        etherpad_ip      => $etherpad_ip,
        etherpad_port    => $etherpad_port,
        etherpad_db_user => $passwords::etherpad_lite::etherpad_db_user,
        etherpad_db_host => $passwords::etherpad_lite::etherpad_db_host,
        etherpad_db_name => $passwords::etherpad_lite::etherpad_db_name,
        etherpad_db_pass => $passwords::etherpad_lite::etherpad_db_pass,
    }

    include ::apache::mod::rewrite
    include ::apache::mod::proxy
    include ::apache::mod::proxy_http
    include ::apache::mod::ssl

    ::apache::site { 'etherpad.wikimedia.org':
        content => template('misc/etherpad.wikimedia.org.erb'),
    }

    # Icinga process monitoring, RT #5790
    nrpe::monitor_service { 'etherpad-lite-proc':
        description   => 'etherpad_lite_process_running',
        nrpe_command  => "/usr/lib/nagios/plugins/check_procs -c 1:1 --ereg-argument-array='^/usr/bin/node /usr/share/etherpad-lite/node_modules/ep_etherpad-lite/node/server.js'",
    }

    monitor_service { 'etherpad-lite-http':
        description   => 'etherpad.wikimedia.org',
        check_command => 'check_http_url!etherpad.wikimedia.org!/',
    }
    monitor_service { 'etherpad-lite-https':
        description   => 'etherpad.wikimedia.org',
        check_command => 'check_https_url_for_string!etherpad.wikimedia.org!//p/Etherpad!\'<title>Etherpad\'',
    }

    ferm::service { 'etherpad_http':
        proto   => 'tcp',
        port    => 'http',
    }

    ferm::service { 'etherpad_https':
        proto   => 'tcp',
        port    => 'https',
    }
}
