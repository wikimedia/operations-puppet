# = Class: nagios_common::commands
# Collection of custom nagios check plugins we use
#
# [*config_dir*]
#   The base directory to put configuration directory in.
#   Defaults to '/etc/icinga/'
#
# [*owner*]
#   The user which should own the check config files.
#   Defaults to 'icinga'
#
# [*group*]
#   The group which should own the check config files.
#   Defaults to 'icinga'
#
class nagios_common::commands(
    $config_dir = '/etc/icinga',
    $owner = 'icinga',
    $group = 'icinga',
) {

    require_package([
        'libnagios-plugin-perl',
        # check_ssl
        'libnet-ssleay-perl',
        'libio-socket-ssl-perl',
        'libio-socket-inet6-perl',
        # check_bgp/check_jnx_alarms
        'libnet-snmp-perl',
        'libtime-duration-perl',
        # check_prometheus_metric
        'jq',
        'curl',
    ])

    file { "${config_dir}/commands":
        ensure => directory,
        owner  => $owner,
        group  => $group,
        mode   => '0755',
    }

    nagios_common::check_command { [
        'check_all_memcached.php',
        'check_bgp',
        'check_dsh_groups',
        'check_grafana_alert',
        'check_graphite',
        'check_graphite_freshness',
        'check_ifstatus_nomon',
        'check_jnx_alarms',
        'check_ores_workers',
        'check_prometheus_metric',
        'check_ssl',
        'check_sslxNN',
        'check_to_check_nagios_paging',
        'check_wikidata',
    ] :
        require    => File["${config_dir}/commands"],
        config_dir => $config_dir,
        owner      => $owner,
        group      => $group,
    }

    nagios_common::check_command::config { [
        'apt',
        'breeze',
        'check_ssl_unified',
        'dhcp',
        'disk',
        'disk-smb',
        'dns',
        'dummy',
        'flexlm',
        'ftp',
        'http',
        'ifstatus',
        'ldap',
        'load',
        'mail',
        'mrtg',
        'mysql',
        'netware',
        'news',
        'nt',
        'ntp',
        'pgsql',
        'ping',
        'procs',
        'radius',
        'real',
        'rpc-nfs',
        'snmp',
        'ssh',
        'tcp_udp',
        'telnet',
        'users',
        'vsz',
    ] :
        require    => File["${config_dir}/commands"],
        config_dir => $config_dir,
        owner      => $owner,
        group      => $group,
    }

    # Used for cluster checks of "modern" wmf services
    require_package('python-service-checker')

    nagios_common::check_command::config { 'check_wmf_service':
        ensure     => present,
        source     => 'puppet:///modules/nagios_common/check_commands/check_wmf_service.cfg',
        content    => undef,
        config_dir => $config_dir,
        owner      => $owner,
        group      => $group
    }

    # Check that the icinga config works
    nagios_common::check_command { 'check_icinga_config':
        ensure         => present,
        config_content => template('nagios_common/check_icinga_config.cfg.erb'),
        config_dir     => $config_dir,
        owner          => $owner,
        group          => $group,
        require        => File["${config_dir}/commands"],
    }

    file { "${config_dir}/checkcommands.cfg":
        source => 'puppet:///modules/nagios_common/checkcommands.cfg',
        owner  => $owner,
        group  => $group,
        mode   => '0644',
    }
}
