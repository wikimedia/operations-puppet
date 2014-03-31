#  Install an http proxy for pmtpa labs instances.
#
#  If this is installed, addresses like foo.pmtpa-proxy.wmflabs.org will
#  be directed to foo.pmtpa.wmflabs.
class role::pmtpa-proxy {

    $proxy_hostname = 'pmtpa-proxy'
    $proxy_internal_domain = 'pmtpa.wmflabs'

    nginx::site { 'pmtpa-labs-proxy':
        content => template('nginx/sites/labs-proxy.erb'),
    }

    file {
        '/var/www':
            ensure  => 'directory',
            owner   => 'root',
            group   => 'root',
            mode    => '0555';
        '/var/www/robots.txt':
            ensure  => 'present',
            require => File['/var/www'],
            mode    => '0444',
            owner   => 'root',
            group   => 'root',
            source  => 'puppet:///files/misc/robots-txt-disallow';
    }
}

#  Install an http proxy for eqiad labs instances.
#
#  If this is installed, addresses like foo.eqiad-proxy.wmflabs.org will
#  be directed to foo.eqiad.wmflabs.
class role::eqiad-proxy {

    $proxy_hostname = 'eqiad-proxy'
    $proxy_internal_domain = 'eqiad.wmflabs'

    nginx::site { 'eqiad-labs-proxy':
        content => template('nginx/sites/labs-proxy.erb'),
    }

    file {
        '/var/www':
            ensure  => 'directory',
            owner   => 'root',
            group   => 'root',
            mode    => '0555';
        '/var/www/robots.txt':
            ensure  => 'present',
            require => File['/var/www'],
            mode    => '0444',
            owner   => 'root',
            group   => 'root',
            source  => 'puppet:///files/misc/robots-txt-disallow';
    }
}

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
        resolver             => '10.68.16.1'
    }
    include dynamicproxy::api
}
