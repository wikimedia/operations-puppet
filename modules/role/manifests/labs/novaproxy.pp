# A dynamic HTTP routing proxy, based on nginx+lua+redis
# Is accessed from Special:NovaProxy in wikitech
#
# filtertags: labs-project-openstack labs-project-project-proxy
class role::labs::novaproxy(
    $all_proxies,
    $active_proxy,
    $use_ssl = true,
) {
    include ::profile::base::firewall

    $proxy_nodes = join($all_proxies, ' ')
    # Open up redis to all proxies!
    ferm::service { 'redis-replication':
        proto  => 'tcp',
        port   => '6379',
        srange => "@resolve((${proxy_nodes}))",
    }

    ferm::service{ 'http':
        proto => 'tcp',
        port  => '80',
        desc  => 'HTTP webserver for the entire world',
    }

    ferm::service{ 'https':
        proto => 'tcp',
        port  => '443',
        desc  => 'HTTPS webserver for the entire world',
    }

    ferm::service { 'dynamicproxy-api-http':
        port  => '5668',
        proto => 'tcp',
        desc  => 'API for adding / removing proxies from dynamicproxy domainproxy'
    }

    ferm::service { 'dynamicproxy-api-http-readonly':
        port  => '5669',
        proto => 'tcp',
        desc  => 'read-only API for viewing proxies from dynamicproxy domainproxy'
    }

    if $::hostname != $active_proxy {
        $redis_replication = {
            "${::hostname}" => $active_proxy
        }
    } else {
        $redis_replication = undef
    }

    if $use_ssl {
        sslcert::certificate { 'star.wmflabs.org': skip_private => true }

        $ssl_settings = ssl_ciphersuite('nginx', 'compat', false)
        class { '::dynamicproxy':
            ssl_certificate_name => 'star.wmflabs.org',
            ssl_settings         => $ssl_settings,
            set_xff              => true,
            luahandler           => 'domainproxy',
            redis_replication    => $redis_replication,
            require              => Sslcert::Certificate['star.wmflabs.org'],
        }
    } else {
        class { '::dynamicproxy':
            set_xff           => true,
            luahandler        => 'domainproxy',
            redis_replication => $redis_replication,
        }
    }

    include dynamicproxy::api

    nginx::site { 'wmflabs.org':
        content => template('role/labs/novaproxy-wmflabs.org.conf')
    }
}
