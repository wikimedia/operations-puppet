# == Class: citoid
#
# citoid is a node.js backend for citation lookups.
#
# === Parameters
#
# [*port*]
#   Port where to run the citoid service. Defaults to 1970.
#
class citoid( $port = 1970 ) {
    require_package('nodejs')
    require_package('firefox')

    package { 'citoid/deploy':
        provider => 'trebuchet',
    }

    group { 'citoid':
        ensure => present,
        name   => 'citoid',
        system => true,
    }

    user { 'citoid':
        gid    => 'citoid',
        home   => '/nonexistent',
        shell  => '/bin/false',
        system => true,
        before => Service['citoid'],
    }

    file { '/var/log/citoid':
        ensure => directory,
        owner  => 'citoid',
        group  => 'citoid',
        mode   => '0775',
        before => Service['citoid'],
    }

    file { '/etc/init/citoid.conf':
        content => template('citoid/upstart-citoid.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['citoid'],
    }

    file { '/etc/logrotate.d/citoid':
        content => template('citoid/logrotate.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    service { 'citoid':
        ensure     => running,
        hasstatus  => true,
        hasrestart => true,
        provider   => 'upstart',
    }

    file { '/etc/init/zotero.conf':
        content => template('citoid/upstart-zotero.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['zotero'],
    }

    service { 'zotero':
        ensure     => running,
        hasstatus  => true,
        hasrestart => true,
        provider   => 'upstart',
    }
}
