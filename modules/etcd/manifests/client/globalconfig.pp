# class etcd::client::globalconfig
# Simple class that installs a world-readable basic config for
# etcd in yaml format. All our software that interacts with etcd
# can understand the configuration from this file.
class etcd::client::globalconfig(
    Stdlib::Host           $srv_domain = "${::site}.wmnet",
    Optional[Stdlib::Host] $host = undef,
    Optional[Stdlib::Port] $port = undef,
    ) {

    # Initially added for etcd-manage, but it's not really clear
    # if any roles implicitly depend on it, so keep older distros
    if debian::codename::lt('bullseye'){
        ensure_packages('python-etcd')
    }

    file { '/etc/etcd':
        ensure => directory,
        mode   => '0755',
    }

    etcd::client::config { '/etc/etcd/etcdrc':
        world_readable => true,
        settings       => {
            host            => $host,
            port            => $port,
            srv_domain      => $srv_domain,
            ca_cert         => $facts['puppet_config']['localcacert'],
            protocol        => 'https',
            allow_reconnect => true,
        },
    }
}
