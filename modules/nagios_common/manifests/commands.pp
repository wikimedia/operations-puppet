# = Class: nagios_common::commands
# Collection of custom nagios check plugins we use
#
# [*config_dir*]
#   The base directory to put configuration directory in.
#   Defaults to '/etc/icinga/'
#
# [*owner*]
#   The user which should own the check config files.
#   Defaults to 'root'
#
# [*group*]
#   The group which should own the check config files.
#   Defaults to 'root'
#
class nagios_common::commands(
    $config_dir = '/etc/icinga',
    $owner = 'root',
    $group = 'root',
) {

    file { "$config_dir/commands":
        ensure => directory,
        owner  => $owner,
        group  => $group,
        mode   => '0755',
    }

    nagios_common::check_command { [
        'check_graphite',
        'check_dsh_groups',
        'check_wikidata',
        'check_cert',
        'check_solr',
        'check_all_memcached.php',
    ] :
        require    => File["$config_dir/commands"],
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
    ] :
        require    => File["$config_dir/commands"],
        config_dir => $config_dir,
        owner      => $owner,
        group      => $group,
    }

    nagios_common::check_command { 'check_ssl_cert':
        require       => File["$config_dir/commands"],
        config_dir    => $config_dir,
        owner         => $owner,
        group         => $group,
        plugin_source => 'puppet:///modules/nagios_common/check_commands/check_ssl_cert/check_ssl_cert',
    }

}
