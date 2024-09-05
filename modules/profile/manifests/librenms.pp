# SPDX-License-Identifier: Apache-2.0
# http://www.librenms.org/ | https://github.com/librenms/librenms

# $active_server
# Which of the netmon servers should actually poll data and
# have active systemd timers. We don't want both to do it at the same time.
# Switch it in hieradata/common.yaml, the default is just a fallback.
#
class profile::librenms (
    Stdlib::Fqdn        $active_server   = lookup('netmon_server'),
    Array[Stdlib::Fqdn] $passive_servers = lookup('netmon_servers_failover'),
    Stdlib::Fqdn        $graphite_host   = lookup('graphite_host'),
    String              $graphite_prefix = lookup('profile::librenms::graphite_prefix'),
    String              $sitename        = lookup('profile::librenms::sitename'),
    Stdlib::Unixpath    $install_dir     = lookup('profile::librenms::install_dir'),
    String              $laravel_app_key = lookup('profile::librenms::laravel_app_key'),

    String              $db_user         = lookup('profile::librenms::dbuser'),
    String              $db_password     = lookup('profile::librenms::dbpassword'),
    Stdlib::Fqdn        $db_host         = lookup('profile::librenms::dbhost'),
    String              $db_name         = lookup('profile::librenms::dbname'),

    Hash                $ldap_config     = lookup('ldap'),
    Enum['ldap','sso']  $auth_mechanism  = lookup('profile::librenms::auth_mechanism')
){

    include network::constants
    include passwords::network

    $config = {
        'title_image'      => '//upload.wikimedia.org/wikipedia/commons/thumb/0/0c/Wikimedia_Foundation_logo_-_horizontal_%282012-2016%29.svg/140px-Wikimedia_Foundation_logo_-_horizontal_%282012-2016%29.svg.png',
        'base_url'         => "https://${sitename}",

        # disable evil daily auto-git pull
        'update'           => 0,

        # Note that the DB settings will be copied in $install_dir/.env too
        'db_host'          => $db_host,
        'db_user'          => $db_user,
        'db_pass'          => $db_password,
        'db_name'          => $db_name,
        'db'               => {
            'extension' => 'mysqli',
        },

        # https://docs.librenms.org/Support/Cleanup-options/
        'device_perf_purge' => 30,
        'eventlog_purge'    => 360,
        'perf_times_purge'  => 90,
        'syslog_purge'      => 15,

        'snmp'             => {
            'community' => [ $passwords::network::snmp_ro_community ],
            # Provide an empty 'v3' section for SNMP v3 "addhost" to work
            # https://github.com/librenms/librenms/issues/13390
            'v3'        => [
              { 'authname' => 'root' },
            ],
        },

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
            'esams' => 'Vancis, Amsterdam, The Netherlands',
            'eqsin' => 'Equinix, Singapore',
            'drmrs' => 'Interxion, Marseille, France',
            'magru' => 'Ascenty SP3, Sao Paulo, Brazil',
        },
        'astext'       => {
            '64600' => 'PyBal',
            '64601' => 'Kubernetes',
            '64602' => 'Kubernetes',
            '64603' => 'Kubernetes',
            '64605' => 'Anycast',
            '64700' => 'frack-eqiad',
            '64701' => 'frack-codfw',
            '65001' => 'confed-eqiad',
            '65002' => 'confed-eqdfw-codfw',
            '65003' => 'confed-esams',
            '65004' => 'confed-ulsfo',
            '65005' => 'confed-eqsin',
            '65006' => 'confed-drmrs',
            '65007' => 'confed-magru',
            '65020' => 'confed-eqord',
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
        'auth_mechanism'     => $auth_mechanism,

        'graphite'   => {
            'enable' => true,
            'host'   => $graphite_host,
            'port'   => '2003',
            'prefix' => $graphite_prefix,
        },
    }

    $ldap = {
        'auth_ldap_server'   => "ldap://${ldap_config[ro-server]} ldap://${ldap_config[ro-server-fallback]}",
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
        'auth_ldap_group'  => [
            'cn=ops,ou=groups,dc=wikimedia,dc=org',
            'cn=wmf,ou=groups,dc=wikimedia,dc=org',
            'cn=nda,ou=groups,dc=wikimedia,dc=org'
        ],
        'auth_ldap_groups' => {'ops' => {'level' => 10}, 'wmf' => {'level' => 5}, 'nda' => {'level' => 5}},
    }
    $sso = {
        'sso' => {
            'mode'            => 'env',
            'user_attr'       => 'HTTP_X_CAS_UID',
            'realname_attr'   => 'HTTP_X_CAS_CN',
            'email_attr'      => 'HTTP_X_CAS_MAIL',
            'create_users'    => true,
            'update_users'    => true,
            'group_strategy'  => 'map',
            'group_attr'      => 'HTTP_X_CAS_MEMBEROF',
            'group_level_map' => {
                'cn=ops,ou=groups,dc=wikimedia,dc=org' => 10,
                'cn=wmf,ou=groups,dc=wikimedia,dc=org' => 5,
                'cn=nda,ou=groups,dc=wikimedia,dc=org' => 5,
            },
            'group_delimiter' => ':',
        }
    }

    $_config = $auth_mechanism ? {
        'sso'   => $config + $sso,
        default => $config + $ldap,
    }
    class { 'librenms':
        install_dir     => $install_dir,
        rrd_dir         => '/srv/librenms/rrd',
        config          => $_config,
        active_server   => $active_server,
        laravel_app_key => $laravel_app_key,
    }
    class { 'librenms::syslog':
        require => Class['librenms']
    }

    include profile::librenms::web

    firewall::service { 'librenms-rsyslog':
        proto => 'udp',
        port  => 514,
    }

    firewall::service { 'librenms-http':
        proto => 'tcp',
        port  => 80,
    }

    firewall::service { 'librenms-https':
        proto => 'tcp',
        port  => 443,
    }

    backup::set {'librenms': }

    $passive_servers.each |Stdlib::Fqdn $passive_server| {
        rsync::quickdatacopy { "srv-librenms-rrd-${passive_server}":
            ensure              => present,
            auto_sync           => false,
            source_host         => $active_server,
            dest_host           => $passive_server,
            module_path         => '/srv/librenms/rrd',
            server_uses_stunnel => true,
            chown               => 'librenms:librenms',
        }

        profile::auto_restarts::service { 'rsync': }
    }
}
