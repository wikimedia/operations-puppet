class role::librenms {
    system::role { 'librenms': description => 'LibreNMS' }

    include network::constants
    include passwords::librenms
    include passwords::network

    $sitename = 'librenms.wikimedia.org'

    # FIXME: deployment::target really needs to handle this better
    file { [ '/srv/deployment', '/srv/deployment/librenms' ]:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    deployment::target { 'librenms': }
    $install_dir = '/srv/deployment/librenms/librenms'

    $config = {
        'title_image'      => 'url(//upload.wikimedia.org/wikipedia/commons/thumb/c/c4/Wikimedia_Foundation_RGB_logo_with_text.svg/100px-Wikimedia_Foundation_RGB_logo_with_text.svg.png)',

        'install_dir'      => $install_dir,
        'html_dir'         => "${install_dir}/html",
        'rrd_dir'          => '/srv/librenms/rrd',
        'log_file'         => '/var/log/librenms.log',

        'db_host'          => 'db1001.eqiad.wmnet',
        'db_user'          => $passwords::librenms::db_user,
        'db_pass'          => $passwords::librenms::db_pass,
        'db_name'          => 'librenms',

        'snmp'             => {
            'community' => [ $passwords::network::snmp_ro_community ],
        },

        'nets'             => $network::constants::external_networks,
        'autodiscovery'    => {
            'xdp'      => true,
            'ospf'     => true,
            'bgp'      => false,
            'snmpscan' => false,
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
    }

    class { '::librenms':
        install_dir => $install_dir,
        config      => $config,
    }

    install_certificate { $sitename: }

    @webserver::apache::module { [ 'php5', 'rewrite' ]: }
    @webserver::apache::site { $sitename:
        docroot => "${install_dir}/html",
        ssl     => 'redirected',
        require => [
            Webserver::Apache::Module['php5'],
            Install_certificate[$sitename],
            Class['::librenms'],
        ],
    }

    # redirect the old, pre-Jan 2014 name to librenms
    @webserver::apache::site { 'observium.wikimedia.org':
        custom => [ "Redirect permanent / https://${sitename}/" ],
    }

    monitor_service { 'librenms':
        description   => 'LibreNMS HTTPS',
        check_command => "check_https_url!${sitename}!http://${sitename}",
    }
}
