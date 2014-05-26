# A dynamic HTTP routing proxy, based on nginx+lua+redis
class role::dynamicproxy::pmtpa {
    install_certificate{ 'star.wmflabs.org':
        privatekey => false
    }
    class { '::dynamicproxy':
        ssl_certificate_name => 'star.wmflabs.org',
        set_xff              => true,
        resolver             => '10.4.0.1'
    }
    include dynamicproxy::api
}

# A dynamic HTTP routing proxy, based on nginx+lua+redis
class role::dynamicproxy::eqiad {
    install_certificate{ 'star.wmflabs.org':
        privatekey => false
    }
    class { '::dynamicproxy':
        ssl_certificate_name => 'star.wmflabs.org',
        set_xff              => true,
        resolver             => '10.68.16.1',
        require              => Install_certificate['star.wmflabs.org']
    }
    include dynamicproxy::api
}
