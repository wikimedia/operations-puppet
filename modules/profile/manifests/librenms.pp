# http://www.librenms.org/ | https://github.com/librenms/librenms

# $active_server
# Which of the netmon servers should actually poll data and
# have active cron jobs. We don't want both to do it at the same time.
# Switch it in hieradata/common.yaml, the default is just a fallback.
#
class profile::librenms (
    Stdlib::Fqdn $sitename = hiera('profile::librenms::sitename'),
    Stdlib::Unixpath $install_dir = hiera('profile::librenms::install_dir'),
    Stdlib::Fqdn $active_server = hiera('netmon_server'),
    Stdlib::Fqdn $graphite_host = hiera('graphite_host', 'graphite-in.eqiad.wmnet'),
    Stdlib::Fqdn $graphite_prefix = hiera('graphite_prefix', 'librenms'),
    String $laravel_app_key = hiera('profile::librenms::laravel_app_key'),

    String $librenms_db_user = hiera('profile::librenms::dbuser'),
    String $librenms_db_password = hiera('profile::librenms::dbpassword'),
    Stdlib::Fqdn $librenms_db_host = hiera('profile::librenms::dbhost'),
    String $librenms_db_name = hiera('profile::librenms::dbname'),

    String $librenms_irc_password = hiera('profile::librenms::irc_password'),
){

    include ::network::constants
    include ::passwords::network

    $config = {
        'title_image'      => '//upload.wikimedia.org/wikipedia/commons/thumb/0/0c/Wikimedia_Foundation_logo_-_horizontal_%282012-2016%29.svg/140px-Wikimedia_Foundation_logo_-_horizontal_%282012-2016%29.svg.png',

        # disable evil daily auto-git pull
        'update'           => 0,

        'db_host'          => $librenms_db_host,
        'db_user'          => $librenms_db_user,
        'db_pass'          => $librenms_db_password,
        'db_name'          => $librenms_db_name,
        'db'               => {
            'extension' => 'mysqli',
        },

        'snmp'             => {
            'community' => [ $passwords::network::snmp_ro_community ],
        },
        'irc_host'         => 'irc.freenode.org',
        'irc_chan'         => '#wikimedia-operations',
        'irc_alert'        => true,
        'irc_debug'        => false,
        'irc_alert_chan'   => '#wikimedia-operations',
        'irc_alert_utf8'   => true,
        'irc_alert_short'  => true,
        'irc_nick'         => 'librenms-wmf',
        'irc_pass'         => "librenms-wmf:${librenms_irc_password}",

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
        'location_map'       => {
            'eqiad' => 'Equinix, Ashburn, Virginia, USA',
            'codfw' => 'CyrusOne, Carrollton, Texas, USA',
            'eqdfw' => 'Equinix, Carrollton, Texas, USA',
            'ulsfo' => 'United Layer, San Francisco, California, USA',
            'eqord' => 'Equinix, Chicago, Illinois, USA',
            'knams' => 'Vancis, Amsterdam, The Netherlands',
            'esams' => 'EvoSwitch, Amsterdam, The Netherlands',
            'eqsin' => 'Equinix, Singapore',
        },
        'astext'       => {
            '64600' => 'PyBal',
            '64601' => 'Kubernetes',
            '64602' => 'Kubernetes',
            '64603' => 'Kubernetes',
            '64700' => 'frack-eqiad',
            '64701' => 'frack-codfw',
            '65001' => 'confed-eqiad-eqord',
            '65002' => 'confed-eqdfw-codfw',
            '65003' => 'confed-esams',
            '65004' => 'confed-ulsfo',
            '65005' => 'confed-eqsin',
            '65517' => 'Equinix',
        },
        'twofactor' => true,
        'twofactor_lock' => 300,
        'rancid_configs'         => ['/var/lib/rancid/core/configs/'],
        'rancid_ignorecomments'  => 1,
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
            'preauth',
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

        'graphite'   => {
            'enable' => true,
            'host'   => $graphite_host,
            'port'   => '2003',
            'prefix' => $graphite_prefix,
        },
    }

    class { '::librenms':
        install_dir     => $install_dir,
        rrd_dir         => '/srv/librenms/rrd',
        config          => $config,
        active_server   => $active_server,
        laravel_app_key => $laravel_app_key,
    }
    class { '::librenms::syslog':
        require => Class['::librenms']
    }

    class { '::librenms::web':
        sitename      => $sitename,
        install_dir   => $install_dir,
        require       => Class['::librenms'],
        active_server => $active_server,
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

    rsync::quickdatacopy { 'srv-librenms-rrd':
        ensure      => present,
        auto_sync   => false,
        source_host => 'netmon1002.wikimedia.org',
        dest_host   => 'netmon2001.wikimedia.org',
        module_path => '/srv/librenms/rrd',
    }
}
