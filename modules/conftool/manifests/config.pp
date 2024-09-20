# == Class conftool::config
#
# Sets up the conftool configuration
#
# === Parameters
#
# [*namespace*] The namespace of the conftool keys.
#
# [*tcpircbot_host*] The host to connect to for tcpircbot
#
# [*tcprircbot_port*] The port to connect to for tcpircbot
#
# [*hosts*] List of etcd hosts (not needed if using srv discovery), empty by default
#
# [*conftool2git_address*] The address of the conftool2git server, if any
#
class conftool::config ($namespace, $tcpircbot_host, $tcpircbot_port, $hosts = [], $conftool2git_address = '') {
    file { '/etc/conftool':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    $config = {
        'hosts'          => $hosts,
        'tcpircbot_host' => $tcpircbot_host,
        'tcpircbot_port' => $tcpircbot_port,
        'driver_options' => {
            'allow_reconnect'       => true,
            'suppress_san_warnings' => false
        },
        'namespace'      => $namespace,
    }
    if $conftool2git_address != '' {
        $extra_config = {
            'conftool2git_address' => $conftool2git_address,
        }
    } else {
        $extra_config = {}
    }

    file { '/etc/conftool/config.yaml':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => to_yaml($config + $extra_config),
    }

}
