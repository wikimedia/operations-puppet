# A dynamic HTTP routing proxy, based on the dynamicproxy module.
class toollabs::proxy inherits toollabs {
    include toollabs::infrastructure

    install_certificate { 'star.wmflabs.org':
        privatekey => false
    }

    class { '::dynamicproxy':
        luahandler           => 'urlproxy',
        resolver             => '10.68.16.1', # eqiad DNS resolver
        ssl_certificate_name => 'star.wmflabs.org',
        require              => Install_certificate['star.wmflabs.org']
    }

    file { '/usr/local/sbin/proxylistener':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => 'puppet:///modules/toollabs/proxylistener.py',
        # Is provided by the dynamicproxy class.
        require => Package['python-redis']
    }

    file { '/etc/init/proxylistener.conf':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/toollabs/proxylistener.conf',
    }
}
