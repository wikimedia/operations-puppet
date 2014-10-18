# == Class: mathoid
#
# Mathoid is an application which takes various forms of math input and
# converts it to MathML + SVG output. It is a web-service implemented
# in node.js.
#
class mathoid {
    require_package('nodejs')

    # Pending fix for <https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=742347>
    # require_package('node-jsdom')

    package { 'mathoid/mathoid':
        provider => 'trebuchet',
        before   => Service['mathoid'],
    }

    group { 'mathoid':
        ensure => present,
        system => true,
    }

    user { 'mathoid':
        gid    => 'mathoid',
        home   => '/nonexistent',
        shell  => '/bin/false',
        system => true,
    }

    file { '/var/log/mathoid':
        ensure => directory,
        owner  => 'mathoid',
        group  => 'mathoid',
        mode   => '0775',
        before => Service['mathoid'],
    }

    file { '/srv/deployment/mathoid/mathoid/mathoid.config.json':
        content => "{}\n",
        owner   => 'mathoid',
        group   => 'mathoid',
        mode    => '0444',
        require => Package['mathoid/mathoid'],
    }

    file { '/etc/init/mathoid.conf':
        source => 'puppet:///modules/mathoid/mathoid.conf',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        notify => Service['mathoid'],
    }

    file { '/etc/logrotate.d/mathoid':
        source => 'puppet:///modules/mathoid/mathoid.logrotate',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }

    service { 'mathoid':
        ensure   => running,
        provider => 'upstart',
    }
}
