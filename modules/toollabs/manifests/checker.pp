# = Class: toollabs::checker
#
# Exposes a set of web endpoints that perform an explicit check for a
# particular set of internal services, and response OK (200) or not (anything else)
# Used for external monitoring / collection of availability metrics
#
# This runs as an ldap user, toolschecker, so it can touch NFS without causing
# idmapd related issues.
class toollabs::checker {
    include toollabs::infrastructure
    include gridengine::submit_host

    require_package('python-flask', 'python-redis')

    file { '/usr/local/lib/python2.7/dist-packages/toolschecker.py':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/toollabs/toolschecker.py',
        notify => Service['toolschecker'],
    }

    file { '/run/toolschecker':
        ensure => directory,
        owner  => 'tools.toolschecker',
        group  => 'www-data',
        mode   => '0755',
    }

    file { '/etc/init/toolschecker.conf':
        ensure => present,
        source => 'puppet:///modules/toollabs/toolschecker.upstart',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        notify => Service['toolschecker'],
    }

    service { 'toolschecker':
        ensure    => running,
        require => File['/run/toolschecker'],
    }


    nginx::site { 'toolschecker-nginx':
        require => Service['toolschecker'],
        content => template('toollabs/toolschecker.nginx.erb'),
    }
}
