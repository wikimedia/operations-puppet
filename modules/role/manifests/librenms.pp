# http://www.librenms.org/ | https://github.com/librenms/librenms
class role::librenms {
    system::role { 'librenms': description => 'LibreNMS' }

    include network::constants
    include passwords::librenms
    include passwords::network

    $sitename = 'librenms.wikimedia.org'
    $install_dir = '/srv/deployment/librenms/librenms'

    # NOTE: scap will manage the deploy user
    scap::target { 'librenms/librenms':
        deploy_user => 'deploy-librenms',
        before      => Class['::librenms'],
    }

    package { 'php5-ldap':
        ensure => present,
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
        'irc_host'         => 'irc.freenode.org',
        'irc_port'         => '+6697',
        'irc_chan'         => '#wikimedia-netops',
        'irc_alert'        => true,
        'irc_debug'        => false,
        'irc_alert_chan'   => '#wikimedia-netops',
        'irc_alert_utf8'   => true,
        'irc_nick'         => 'librenms-wmf',

        'autodiscovery'    => {
            'xdp'      => true,
            'ospf'     => true,
            'bgp'      => false,
            'snmpscan' => false,
        },
        'geoloc'             => {
            'latlng' => true,
            'engine' => 'google',
        },
        'leaflet'             => {
            'tile_url' => 'maps.wikimedia.org',
        },
        'location_map'       => {
            'eqiad' => 'Equinix, Ashburn, Virginia, USA',
            'codfw' => 'CyrusOne, Carrollton, Texas, USA',
            'eqdfw' => 'Equinix, Carrollton, Texas, USA',
            'ulsfo' => 'United Layer, San Francisco, California, USA',
            'eqord' => 'Equinix, Chicago, Illinois, USA',
            'knams' => 'Vancis, Amsterdam, The Netherlands',
            'esams' => 'EvoSwitch, Amsterdam, The Netherlands',

        },
        'email_from' => 'librenms',
        'enable_inventory' => 1,
        'enable_syslog'    => 1,
        'enable_billing'   => 1,
        'syslog_filter'    => [
            'message repeated',
            'Connection from UDP: [',
            'CMD (   /usr/libexec/atrun)',
            'CMD (newsyslog)',
            'CMD (adjkerntz -a)',
            'kernel time sync enabled',
            'fatal: Write failed: Broken pipe [preauth]',
            'fatal: Read from socket failed: Connection reset by peer [preauth]',
            'fatal: no hostkey alg [preauth]',
        ],

        'auth_mechanism'     => 'ldap',
        'auth_ldap_server'   => 'ldap://ldap-labs.eqiad.wikimedia.org  ldap://ldap-labs.codfw.wikimedia.org',
        'auth_ldap_starttls' => 'require',
        'auth_ldap_port'     => 389,

        # This is dumb -- the code requires us to specify the dn rather
        #  than doing a search, so logins will require 'shell name' rather
        #  than the more-traditional 'wikitech name'
        'auth_ldap_prefix'  => 'uid=',
        'auth_ldap_suffix'  => ',ou=people,dc=wikimedia,dc=org',
        'login_message'     => 'Log in with your ldap shell name (NOT the full name used on wikitech) and password.',

        # In our schema, a group is a list of user dns called 'member'
        'auth_ldap_groupbase' => 'ou=groups,dc=wikimedia,dc=org',
        'auth_ldap_groupmemberattr' => 'member',
        'auth_ldap_groupmembertype' => 'fulldn',

        # Give all ops full read/write permissions
        'auth_ldap_group'  => ['cn=ops,ou=groups,dc=wikimedia,dc=org', 'cn=librenms-readers,ou=groups,dc=wikimedia,dc=org'],
        'auth_ldap_groups' => {'ops' => {'level' => 10}, 'librenms-readers' => {'level' => 5}},
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

    ferm::service { 'librenms-rsyslog':
        proto => 'udp',
        port  => '514',
    }

    ferm::service { 'librenms-http':
        proto => 'tcp',
        port  => '80',
    }

    ferm::service { 'librenms-https':
        proto => 'tcp',
        port  => '443',
    }

    backup::set {'librenms': }
}
