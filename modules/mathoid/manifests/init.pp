# == Class: mathoid
#
# Mathoid is an application which takes various forms of math input and
# converts it to MathML + SVG output. It is a web-service implemented
# in node.js.
#
# === Parameters
#
# [*base_path*]
#   Path to the mathoid code.
# [*node_path*]
#   Path to the node modules mathoid depends on.
# [*conf_path*]
#   Where to place the config file.
# [*log_dir*]
#   Place where mathoid can put log files. Assumed to be already existing and
#   have write access to mathoid user.
# [*port*]
#   Port where to run the mathoid service. Defaults to 10042.
#
class mathoid(
    $base_path = '/srv/deployment/mathoid/mathoid',
    $node_path = '/srv/deployment/mathoid/mathoid/node_modules',
    $conf_path = '/srv/deployment/mathoid/mathoid/mathoid.config.json',
    $log_dir = '/var/log/mathoid',
    $port=10042
) {
    require_package('nodejs')

    # Pending fix for <https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=742347>
    # require_package('node-jsdom')

    package { 'mathoid/mathoid':
        ensure   => installed,
        provider => 'trebuchet',
        before   => Service['mathoid'],
    }

    group { 'mathoid':
        ensure => present,
        system => true,
    }

    user { 'mathoid':
        ensure => present,
        gid    => 'mathoid',
        home   => '/',
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
        ensure => present,
        source => 'puppet:///modules/mathoid/mathoid.conf',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        notify => Service['mathoid'],
    }

    file { '/etc/logrotate.d/mathoid':
        ensure => present,
        source => 'puppet:///modules/mathoid/mathoid.logrotate',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }

    service { 'mathoid':
        ensure     => running,
        hasstatus  => true,
        hasrestart => true,
        provider   => 'upstart',
    }
}
