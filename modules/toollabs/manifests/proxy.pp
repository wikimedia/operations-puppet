# A dynamic HTTP routing proxy, based on the dynamicproxy module.
class toollabs::proxy(
    $ssl_certificate_name = 'star.wmflabs.org',
    $ssl_install_certificate = true,
    $web_domain = 'tools.wmflabs.org',
    $proxies = ['tools-webproxy-01', 'tools-webproxy-02'],
) {
    include toollabs::infrastructure
    include ::redis::client::python

    include base::firewall

    if $ssl_install_certificate {
        sslcert::certificate { $ssl_certificate_name:
            skip_private => true,
            before       => Class['::dynamicproxy'],
        }
    }

    $active_proxy = hiera('active_proxy_host')

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
            title    => 'Wikimedia Tool Labs Error',
            logo     => '/tool-labs-logo.png',
            logo_2x  => '/tool-labs-logo-2x.png',
            logo_alt => 'Wikimedia Tool Labs',
            favicon  => '/favicon.ico',
        },
        banned_description   => 'You have been banned from accessing Tool Labs. Please see <a href="//wikitech.wikimedia.org/wiki/Help:Tool_Labs/Banned">Help:Tool Labs/Banned</a> for more information on why and on how to resolve this.',
        web_domain           => $web_domain,
    }


    $proxy_nodes = join($proxies, ' ')

    # Open up redis to all proxies!
    ferm::service { 'redis-replication':
        proto  => 'tcp',
        port   => '6379',
        srange => "@resolve((${proxy_nodes}))",
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

    base::service_unit { 'proxylistener':
        ensure  => present,
        upstart => true,
        systemd => true,
        require => File['/usr/local/sbin/proxylistener'],
    }

    ferm::service { 'proxylistener-port':
        proto  => 'tcp',
        port   => '8282',
        srange => '$INTERNAL',
        desc   => 'Proxylistener port, open to just labs'
    }

    file { '/var/www/error/favicon.ico':
        ensure  => file,
        source  => 'puppet:///modules/toollabs/favicon.ico',
        require => File['/var/www/error'],
    }

    file { '/var/www/error/tool-labs-logo.png':
        ensure  => file,
        source  => 'puppet:///modules/toollabs/tool-labs-logo.png',
        require => [File['/var/www/error']]
    }

    file { '/var/www/error/tool-labs-logo-2x.png':
        ensure  => file,
        source  => 'puppet:///modules/toollabs/tool-labs-logo-2x.png',
        require => [File['/var/www/error']]
    }


}
