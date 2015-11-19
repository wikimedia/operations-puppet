# A dynamic HTTP routing proxy, based on nginx+lua+redis
# Is accessed from Special:NovaProxy in wikitech
class role::labs::novaproxy(
    $all_proxies,
    $active_proxy,
) {
    include base::firewall

    sslcert::certificate { 'star.wmflabs.org': skip_private => true }

    $proxy_nodes = join($all_proxies, ' ')
    # Open up redis to all proxies!
    ferm::service { 'redis-replication':
        proto  => 'tcp',
        port   => '6379',
        srange => "@resolve((${proxy_nodes}))",
    }

    if $::hostname != $active_proxy {
        $redis_replication = {
            "${::hostname}" => $active_proxy
        }
    } else {
        $redis_replication = undef
    }

    class { '::dynamicproxy':
        ssl_certificate_name => 'star.wmflabs.org',
        ssl_settings         => ssl_ciphersuite('nginx', 'compat'),
        set_xff              => true,
        luahandler           => 'domainproxy',
        redis_replication    => $redis_replication,
        require              => Sslcert::Certificate['star.wmflabs.org'],
    }
    include dynamicproxy::api
}
