# == Class: restbase
#
# restbase is a REST API & storage service
#
# === Parameters
#
# [*port*]
#   Port where to run the restbase service. Defaults to 7231.
#
class restbase( $port = 7231 ) {
    ensure_packages( ['nodejs', 'npm'] )

    package { 'restbase/deploy':
        provider => 'trebuchet',
    }

    group { 'restbase':
        ensure => present,
        name   => 'restbase',
        system => true,
    }

    user { 'restbase':
        gid    => 'restbase',
        home   => '/nonexistent',
        shell  => '/bin/false',
        system => true,
        before => Service['restbase'],
    }

    file { '/var/log/restbase':
        ensure => directory,
        owner  => 'restbase',
        group  => 'restbase',
        mode   => '0775',
        before => Service['restbase'],
    }

    file { '/etc/default/restbase':
        content => template('restbase/restbase.default.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['restbase'],
    }

    file { '/etc/init.d/restbase':
        content => template('restbase/restbase.init'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['restbase'],
    }

    file { '/etc/restbase':
        ensure => directory,
        owner  => 'restbase',
        group  => 'restbase',
        mode   => '0775',
        before => Service['restbase'],
    }

    file { '/etc/restbase/config.yaml':
        content => template('restbase/config.yaml.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['restbase'],
    }

    file { '/usr/lib/parsoid':
        ensure => link,
        target => '/srv/deployment/restbase',
        before  => Service['restbase'],
    }

    service { 'restbase':
        ensure     => running,
        hasstatus  => true,
        hasrestart => true,
        provider   => 'init',
    }
}
