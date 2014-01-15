class role::etherpad{

    include passwords::etherpad_lite
    include webserver::apache

    system::role { 'etherpad': description => 'Etherpad-lite server' }
    $etherpad_ip = '127.0.0.1'
    $etherpad_port = '9001'

    case $::realm {
        'labs': {
            $etherpad_host = $::fqdn
            $etherpad_ssl_cert = '/etc/ssl/certs/ssl-cert-snakeoil.pem'
            $etherpad_ssl_key = '/etc/ssl/private/ssl-cert-snakeoil.key'
            $aliases = []
        }
        'production': {
            $etherpad_host = 'etherpad.wikimedia.org'
            install_certificate{ 'etherpad.wikimedia.org': }
            $aliases = ['epl.wikimedia.org']
            $etherpad_ssl_cert = '/etc/ssl/certs/etherpad.wikimedia.org.pem'
            $etherpad_ssl_key = '/etc/ssl/private/etherpad.wikimedia.org.key'
        }
        'default': {
            fail('unknown realm, should be labs or production')
        }
    }

    class { '::etherpad':
        etherpad_host    => $etherpad_host,
        etherpad_ip      => $etherpad_ip,
        etherpad_port    => $etherpad_port,
        etherpad_db_user => $passwords::etherpad_lite::etherpad_db_user,
        etherpad_db_host => $passwords::etherpad_lite::etherpad_db_host,
        etherpad_db_name => $passwords::etherpad_lite::etherpad_db_name,
        etherpad_db_pass => $passwords::etherpad_lite::etherpad_db_pass,
    }
    @webserver::apache::module { [ 'proxy', 'rewrite', 'proxy_http' ]:}
    @webserver::apache::site { $etherpad_host:
        ssl      => 'true',
        aliases  => $aliases,
        includes => ['etherpad_proxy.conf'],
        certfile => $etherpad_ssl_cert,
        certkey  => $etherpad_ssl_key,
    }
    file { '/etc/apache2/etherpad_proxy.conf':
        ensure   => 'present',
        owner    => 'root',
        group    => 'root',
        mode     => '0444',
        content  => template('etherpad/etherpad_proxy.conf.erb'),
        require  => Webserver::Apache::Site[$etherpad_host],
    }

    # Icinga process monitoring, RT #5790
    nrpe::monitor_service { 'etherpad-lite-proc':
        description   => 'etherpad_lite_process_running',
        nrpe_command  => "/usr/lib/nagios/plugins/check_procs -c 1:1 --ereg-argument-array='^node node_modules/ep_etherpad-lite/node/server.js'",
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
