# A dynamic HTTP routing proxy, based on nginx+lua+redis
class role::dynamicproxy {
    include base::firewall

    sslcert::certificate { 'star.wmflabs.org': skip_private => true }

    class { '::dynamicproxy':
        ssl_certificate_name => 'star.wmflabs.org',
        ssl_settings         => ssl_ciphersuite('nginx', 'compat'),
        set_xff              => true,
        luahandler           => 'domainproxy',
        require              => Sslcert::Certificate['star.wmflabs.org'],
    }
    include dynamicproxy::api
}
