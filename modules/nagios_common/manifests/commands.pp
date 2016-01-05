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

    # needed for (at least) check_ssl
    package { [
        'libnagios-plugin-perl',
        'libnet-ssleay-perl',
        'libio-socket-ssl-perl',
        'libio-socket-inet6-perl',
        ]:
            ensure => present,
    }

    file { "${config_dir}/commands":
        ensure => directory,
        owner  => $owner,
        group  => $group,
        mode   => '0755',
    }

    nagios_common::check_command { [
        'check_graphite',
        'check_dsh_groups',
        'check_wikidata',
        'check_ssl',
        'check_sslxNN',
        'check_all_memcached.php',
        'check_to_check_nagios_paging',
        'check_ifstatus_nomon',
        'check_bgp',
        'check_ores_workers',
    ] :
        require    => File["${config_dir}/commands"],
        config_dir => $config_dir,
        owner      => $owner,
        group      => $group,
    }

    nagios_common::check_command::config { [
        'users',
        'telnet',
        'ssh',
        'snmp',
        'real',
        'radius',
        'rpc-nfs',
        'tcp_udp',
        'apt',
        'breeze',
        'dhcp',
        'disk-smb',
        'disk',
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
        'vsz',
    ] :
        require    => File["${config_dir}/commands"],
        config_dir => $config_dir,
        owner      => $owner,
        group      => $group,
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
