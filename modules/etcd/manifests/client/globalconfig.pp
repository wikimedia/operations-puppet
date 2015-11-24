# class etcd::client::globalconfig
# Simple class that installs a world-readable basic config for
# etcd in yaml format. All our software that interacts with etcd
# can understand the configuration from this file.
class etcd::client::globalconfig(
    $host = undef,
    $port = undef,
    $srv_dns = "${::site}.wmnet",
    $protocol = 'https',
    $ssl_dir = undef,
    ) {

    require_package 'python-etcd'

    if $ssl_dir {
        file { '/etc/etcd/ca.pem':
            ensure => present,
            owner  => root,
            group  => root,
            mode   => '0444',
            source => "${ssl_dir}/certs/ca.pem",
        }
        $ca_cert = '/etc/etcd/ca.pem'
    } else {
        $ca_cert = undef
    }

    file { '/etc/etcd':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    etcd::client::config { '/etc/etcd/etcdrc':
        world_readable => true,
        settings       => {
            host    => $host,
            port    => $port,
            srv_dns => $srv_dns,
            ca_cert => $ca_cert,
            protocol => $protocol,
        },
    }
}
