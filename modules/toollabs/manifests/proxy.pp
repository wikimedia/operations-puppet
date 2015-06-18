# A dynamic HTTP routing proxy, based on the dynamicproxy module.
class toollabs::proxy(
    $ssl_certificate_name = 'star.wmflabs.org',
    $ssl_install_certificate = true,
) inherits toollabs {
    include toollabs::infrastructure
    include ::redis::client::python

    include base::firewall

    if $ssl_install_certificate {
        sslcert::certificate { $ssl_certificate_name:
            source => "puppet:///files/ssl/$ssl_certificate_name.crt",
            before => Class['::dynamicproxy'],
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
        ssl_certificate_name => $ssl_certificate_name,
        redis_replication    => $redis_replication,
        error_config         => {
            title => "Wikimedia Tool Labs",
            header => "<img src='/Tool_Labs_logo_thumb.png' alt='Wikimedia Tool Labs' /><br>Wikimedia Tool Labs",
        },
        error_description    => "The Wikimedia Tool Labs servers are currently experiencing a technical problem. We are currently working to resolve this. \
                                 Please try again later.<br/>\
                                 For more information, please join <a href='irc://irc.freenode.net/wikimedia-labs'>#wikimedia-labs</a> on Freenode",
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

    file { '/var/www-error/favicon.ico':
        ensure => file,
        source => '/data/project/admin/toollabs/www/favicon.ico',
        require => [File['/var/www-error'], Git::Clone['labs/toollabs']]
    }

    file { '/var/www-error/Tool_Labs_logo_thumb.png':
        ensure => file,
        source => '/data/project/admin/toollabs/www/Tool_Labs_logo_thumb.png',
        require => [File['/var/www-error'], Git::Clone['labs/toollabs']]
    }

}
