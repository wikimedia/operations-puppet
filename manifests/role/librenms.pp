# http://www.librenms.org/ | https://github.com/librenms/librenms
class role::librenms {
    system::role { 'librenms': description => 'LibreNMS' }

    include network::constants
    include passwords::librenms
    include passwords::network

    $sitename = 'librenms.wikimedia.org'
    $install_dir = '/srv/deployment/librenms/librenms'

    package { 'librenms/librenms':
        provider => 'trebuchet',
    }

    $config = {
        'title_image'      => '//upload.wikimedia.org/wikipedia/commons/thumb/2/2b/Wmf_logo_horiz_pms.svg/140px-Wmf_logo_horiz_pms.svg.png',

        # disable evil daily auto-git pull
        'update'           => 0,

        'db_host'          => 'm1-master.eqiad.wmnet',
        'db_user'          => $passwords::librenms::db_user,
        'db_pass'          => $passwords::librenms::db_pass,
        'db_name'          => 'librenms',
        'db'               => {
            'extension' => 'mysqli',
        },

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
        require     => Package['librenms/librenms'],
    }
    class { '::librenms::syslog':
        require => Class['::librenms']
    }

    class { '::librenms::web':
        sitename    => $sitename,
        install_dir => $install_dir,
        require     => Class['::librenms'],
    }

    ferm::service { 'librenms-http':
        proto => 'tcp',
        port  => '80',
    }

    ferm::service { 'librenms-https':
        proto => 'tcp',
        port  => '443',
    }
}
