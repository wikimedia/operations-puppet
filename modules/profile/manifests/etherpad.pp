# sets up an Etherpad lite server
class profile::etherpad {

    include ::passwords::etherpad_lite
    include ::profile::prometheus::etherpad_exporter

    class { '::etherpad':
        etherpad_db_user => $passwords::etherpad_lite::etherpad_db_user,
        etherpad_db_host => $passwords::etherpad_lite::etherpad_db_host,
        etherpad_db_name => $passwords::etherpad_lite::etherpad_db_name,
        etherpad_db_pass => $passwords::etherpad_lite::etherpad_db_pass,
    }

    # Icinga process monitoring, T82936
    nrpe::monitor_service { 'etherpad-lite-proc':
        description  => 'etherpad_lite_process_running',
        nrpe_command => "/usr/lib/nagios/plugins/check_procs -c 1:1 --ereg-argument-array='^/usr/bin/node /usr/share/etherpad-lite/node_modules/ep_etherpad-lite/node/server.js'",
    }

    monitoring::service { 'etherpad-lite-http':
        description   => 'etherpad.wikimedia.org HTTP',
        check_command => 'check_http_port_url!9001!/',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Etherpad.wikimedia.org',
    }

    ferm::service { 'etherpad_service':
        proto  => 'tcp',
        port   => '9001',
        srange => '$CACHES',
    }

    # Ship etherpad server logs to ELK using startmsg_regex pattern to join multi-line events based on datestamp
    # example: [2018-11-30 21:32:43.412]
    rsyslog::input::file { 'etherpad-multiline':
        path           => '/var/log/etherpad-lite/etherpad-lite.log',
        startmsg_regex => '^\\\\[[0-9,-\\\\ \\\\:]+\\\\]',
    }
}
