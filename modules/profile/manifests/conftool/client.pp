#
# == Class profile::conftool::client
#
# Configures a server to be a conftool client, setting up
#
# - The etcd client configuration in /etc/etcd/etcdrc
# - The conftool client configuration
# - The etcd credentials for the root user in /root/.etcdrc
#
class profile::conftool::client(
    $srv_dns = hiera('etcd::srv_dns'),
    $host = hiera('etcd::host'),
    $port = hiera('etcd::port'),
    $root_password = hiera('etcd::auth::common::root_password'),
    $tcpircbot_host = hiera('profile::conftool::client::tcpircbot_host')
    $tcpircbot_port = hiera('profile::conftool::client::tcpircbot_port'),
    $namespace      = hiera('profile::conftool::client::namespace')
) {
    require_package('python-conftool')

    class { '::etcd::client::globalconfig':
        srv_dns  => $srv_dns,
        host     => $host,
        port     => $port,
        protocol => 'https',
    }

    ::etcd::client::config { '/root/.etcdrc',
        settings => {
            username => 'root',
            password => $root_password,
        },
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

    ::conftool::config {
        namespace      => $namespace,
        tcpircbot_host => $tcpircbot_host,
        tcpircbot_port => $tcpircbot_port,
        hosts          => [],
    }
}
