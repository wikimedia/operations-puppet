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
        }
        'production': {
            $etherpad_host = 'etherpad.wikimedia.org'
        }
        default: {
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

    include ::apache::mod::rewrite
    include ::apache::mod::proxy
    include ::apache::mod::proxy_http

    ::apache::site { 'etherpad.wikimedia.org':
        content => template('misc/etherpad.wikimedia.org.erb'),
    }

    # Icinga process monitoring, RT #5790
    nrpe::monitor_service { 'etherpad-lite-proc':
        description  => 'etherpad_lite_process_running',
        nrpe_command => "/usr/lib/nagios/plugins/check_procs -c 1:1 --ereg-argument-array='^/usr/bin/node /usr/share/etherpad-lite/node_modules/ep_etherpad-lite/node/server.js'",
    }

    monitoring::service { 'etherpad-lite-http':
        description   => 'etherpad.wikimedia.org HTTP',
        check_command => 'check_http_url!etherpad.wikimedia.org!/',
    }

    ferm::service { 'etherpad_http':
        proto => 'tcp',
        port  => 'http',
    }

}
