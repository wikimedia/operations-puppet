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

        'enable_syslog'    => 1,
        'syslog_filter'    => [
            'message repeated',
            'Connection from UDP: [',
            'CMD (   /usr/libexec/atrun)',
            'CMD (newsyslog)',
            'CMD (adjkerntz -a)',
            'kernel time sync enabled',
        ],

        'auth_mechanism'   => 'mysql',
    }

    class { '::librenms':
        install_dir => $install_dir,
        rrd_dir     => '/srv/librenms/rrd',
        config      => $config,
    }
    class { '::librenms::syslog':
        require => Class['::librenms']
    }

    install_certificate { $sitename: }

    include ::apache::mod::php5
    include ::apache::mod::rewrite
    include ::apache::mod::ssl
    @webserver::apache::site { $sitename:
        docroot => "${install_dir}/html",
        ssl     => 'redirected',
        require => [
            Class['::apache::mod::php5', '::apache::mod::ssl'],
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
