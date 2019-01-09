#
# == Class profile::conftool::client
#
# Configures a server to be a conftool client, setting up
#
# - The etcd client configuration in /etc/etcd/etcdrc
# - The conftool client configuration
# - The etcd credentials for the root user in /root/.etcdrc
#
# === Parameters
#
class profile::conftool::client(
    $srv_domain = hiera('etcd_client_srv_domain'),
    $host = hiera('etcd_host'),
    $port = hiera('etcd_port'),
    $namespace      = dirname(hiera('conftool_prefix')),
    $tcpircbot_host = hiera('tcpircbot_host', 'icinga.wikimedia.org'),
    $tcpircbot_port = hiera('tcpircbot_port', 9200),
    $protocol = hiera('profile::conftool::client::protocol', 'https')
) {

    if os_version('debian >= stretch') {
        $socks_pkg = 'python-socks'
    } else {
        $socks_pkg = 'python-pysocks'
    }

    $conftool_pkg = 'python3-conftool'

    require_package(
        $conftool_pkg,
        $socks_pkg,
    )

    require ::passwords::etcd

    class { '::etcd::client::globalconfig':
        srv_domain => $srv_domain,
        host       => $host,
        port       => $port,
        protocol   => $protocol,
    }

    ::etcd::client::config { '/root/.etcdrc':
        settings => {
            username => 'root',
            password => $::passwords::etcd::accounts['root'],
        },
    }

    class  { '::conftool::config':
        namespace      => $namespace,
        tcpircbot_host => $tcpircbot_host,
        tcpircbot_port => $tcpircbot_port,
        hosts          => [],
    }

    # Conftool schema. Let's assume we will only have one.
    file { '/etc/conftool/schema.yaml':
        ensure => present,
        source => 'puppet:///modules/profile/conftool/schema.yaml',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }

    # json schemas container
    file {'/etc/conftool/json-schema/':
        ensure  => directory,
        source  => 'puppet:///modules/profile/conftool/json-schema/',
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        recurse => true,
    }
}
