# == Class profile::discovery::client
#
# Will use confd to watch our discovery system and save the result as a json file in a chosen directory.
#
# === Parameters
#
# [*path*] The directory where the file should go.
#
# [*watch_interval*] The interval in seconds for checks on etcd. Defaults to 5
#
class profile::discovery::client(
    $path=hiera('profile::discovery::path'),
    $watch_interval=hiera('profile::discovery::watch_interval', 5),
    $conftool_prefix = hiera('conftool_prefix'),
){
    file { $path:
        ensure => directory,
        owner  => root,
        group  => root,
        mode   => '0755',
    }

    class { 'confd':
        interval => $watch_interval,
        prefix   => $conftool_prefix,
    }

    confd::file { "${path}/discovery-basic.yaml":
        ensure     => present,
        content    => template('profile/discovery/basic.yaml.tpl.erb'),
        watch_keys => ['/'],
        prefix     => '/discovery',
        mode       => '0444',
        check      => 'ruby -e \"require \'yaml\'; YAML.load_file(\'{{ .src }}\')\"',
    }

    confd::file { "${path}/services.yaml":
        ensure     => present,
        content    => template('profile/discovery/services.yaml.tpl.erb'),
        watch_keys => ['/'],
        prefix     => '/service',
        mode       => '0444',
    }
}
