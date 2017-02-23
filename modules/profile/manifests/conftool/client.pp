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
    $srv_domain = hiera('etcd_client_srv_dns'),
    $host = hiera('etcd_host'),
    $port = hiera('etcd_port'),
    $root_password = hiera('etcd::auth::common::root_password'),
    $namespace      = hiera('profile::conftool::client::namespace', '/conftool'),
    $tcpircbot_host = hiera('profile::conftool::client::tcpircbot_host', 'icinga.wikimedia.org'),
    $tcpircbot_port = hiera('profile::conftool::client::tcpircbot_port', 9200),
) {
    require_package('python-conftool')

    class { '::etcd::client::globalconfig':
        srv_domain => $srv_domain,
        host       => $host,
        port       => $port,
        protocol   => 'https',
    }

    ::etcd::client::config { '/root/.etcdrc':
        settings => {
            username => 'root',
            password => $root_password,
        },
    }

    class  { '::conftool::config':
        namespace      => $namespace,
        tcpircbot_host => $tcpircbot_host,
        tcpircbot_port => $tcpircbot_port,
        hosts          => [],
    }
}
