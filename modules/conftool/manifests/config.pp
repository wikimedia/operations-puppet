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
class conftool::config ($namespace, $tcpircbot_host, $tcpircbot_port, $hosts = []) {
    file { '/etc/conftool':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { '/etc/conftool/config.yaml':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => ordered_yaml({
            hosts          => $hosts,
            tcpircbot_host => $tcpircbot_host,
            tcpircbot_port => $tcpircbot_port,
            driver_options => {
                allow_reconnect => true,
            },
            namespace      => $namespace,
        }),
    }

}
