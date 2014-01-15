class role::etherpad{

    include passwords::etherpad_lite
    include webserver::apache

    system::role { 'etherpad': description => 'Etherpad-lite server' }

    case $::realm {
        'labs': {
            $etherpad_host = $::fqdn
        }
        'production': {
            $etherpad_host = 'etherpad.wikimedia.org'
            install_certificate{ 'etherpad.wikimedia.org': }
        }
        'default': {
            fail('unknown realm, should be labs or production')
        }
    }

    class { '::etherpad':
        etherpad_host    => $etherpad_host,
        etherpad_ip      => '127.0.0.1',
        etherpad_port    => '9001',
        etherpad_db_user => $passwords::etherpad_lite::etherpad_db_user,
        etherpad_db_host => $passwords::etherpad_lite::etherpad_db_host,
        etherpad_db_name => $passwords::etherpad_lite::etherpad_db_name,
        etherpad_db_pass => $passwords::etherpad_lite::etherpad_db_pass,
    }

    # Icinga process monitoring, RT #5790
    nrpe::monitor_service { 'etherpad-lite-proc':
        description   => 'etherpad_lite_process_running',
        nrpe_command  => "/usr/lib/nagios/plugins/check_procs -c 1:1 --ereg-argument-array='^node node_modules/ep_etherpad-lite/node/server.js'",
    }
}
