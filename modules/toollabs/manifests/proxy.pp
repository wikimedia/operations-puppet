# A dynamic HTTP routing proxy, based on the dynamicproxy module.
class toollabs::proxy(
    $ssl_certificate_name = 'star.wmflabs.org',
    $ssl_install_certificate = true,
) inherits toollabs {
    include toollabs::infrastructure
    include ::redis::client::python

    include base::firewall

    if $ssl_install_certificate {
        install_certificate { $ssl_certificate_name:
            privatekey => false,
            before     => Class['::dynamicproxy'],
        }
    }

    if $::hostname != $active_proxy {
        $redis_replication = {
            "${::hostname}" => $active_proxy
        }
    } else {
        $redis_replication = undef
    }

    class { '::dynamicproxy':
        ssl_settings         => ssl_ciphersuite('nginx', 'compat'),
        luahandler           => 'urlproxy',
        resolver             => '10.68.16.1', # eqiad DNS resolver
        ssl_certificate_name => $ssl_certificate_name,
        redis_replication    => $redis_replication,
    }

    $proxy_nodes = join($proxies, ' ') # $proxies comes from toollabs base class
    # Open up redis to all proxies!
    ferm::service { 'redis-replication':
        proto  => 'tcp',
        port   => '6379',
        srange => "@resolve(($proxy_nodes))",
    }

    file { '/usr/local/sbin/proxylistener':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => 'puppet:///modules/toollabs/proxylistener.py',
        # Is provided by the dynamicproxy class.
        require => Class['::redis::client::python'],
    }

    file { '/etc/init/proxylistener.conf':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/toollabs/proxylistener.conf',
        require => File['/usr/local/sbin/proxylistener'],
    }

    service { 'proxylistener':
        ensure  => running,
        require => File['/etc/init/proxylistener.conf'],
    }

    ferm::service { 'proxylistener-port':
        proto  => 'tcp',
        port   => '8282',
        srange => '$INTERNAL',
        desc   => 'Proxylistener port, open to just labs'
    }

    # Deploy root web.
    git::clone { 'labs/toollabs':
        ensure    => latest,
        directory => '/data/project/admin/toollabs',
        owner     => "${instanceproject}.admin",
        group     => "${instanceproject}.admin",
        mode      => '2755',
    }

    file { '/data/project/admin/public_html':
        ensure  => link,
        force   => true,
        target  => 'toollabs/www',
        require => Git::Clone['labs/toollabs'],
    }
}
