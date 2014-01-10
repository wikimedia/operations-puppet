class role::librenms {
    system::role { 'librenms': description => 'LibreNMS' }

    include network::constants
    include passwords::mysql::librenms
    include passwords::network

    $hostname = 'librenms.wikimedia.org'

    deployment::target { 'librenms': }
    $install_dir = '/srv/deployment/librenms/librenms'

    $config = {
        'install_dir'      => $install_dir,
        'html_dir'         => "${install_dir}/html",
        'log_file'         => '/var/log/librenms.log',
        'rrd_dir'          => '/srv/librenms/rrd',

        'db_host'          => 'db1001.eqiad.wmnet',
        'db_user'          => $passwords::mysql::librenms::user,
        'db_pass'          => $passwords::mysql::librenms::pass,
        'db_name'          => 'librenms',

        'snmp'             => {
            'community' => [ $passwords::network::snmp ],
        },

        'enable_inventory' => 1,
        'enable_syslog'    => 1,
        'email_backend'    => 'sendmail',
        'alerts'           => {
            'port_util_alert' => true,
            'port_util_perc'  => 85,
            'email' => {
                'default' => 'noc@wikimedia.org',
                'enable'  => true,
            },
            'port' => {
                'ifdown'  => false,
            },
        },

        'auth_mechanism'   => 'mysql',
        'nets'             => $network::constants::external_networks,
    }

    class { 'librenms':
        install_dir => $install_dir,
        config      => $config,
    }

    @webserver::apache::module { 'php5': }
    @webserver::apache::site { $hostname,
        aliases => [ 'observium.wikimedia.org' ],
        docroot => $install_dir,
        require => [
            Webserver::Apache::Module['php5'],
            Class['librenms'],
        ],
    }

    monitor_service { 'librenms':
        description   => 'HTTP',
        check_command => "check_http_url!${hostname}!http://${hostname}",
    }
}
