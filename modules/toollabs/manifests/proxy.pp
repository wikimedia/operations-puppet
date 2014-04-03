# A dynamic HTTP routing proxy, based on the dynamicproxy module.
class toollabs::proxy inherits toollabs {
    include toollabs::infrastructure

    class { '::dynamicproxy':
        luahandler => 'urlproxy',
        resolver   => '10.68.16.1' # eqiad DNS resolver
    }

    package { 'python-redis':
        ensure => latest
    }

    file { '/usr/local/sbin/proxylistener':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/toollabs/proxylistener.py'
    }

    file { '/etc/init/proxylistener.conf':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/toollabs/proxylistener.conf',
    }
}
