# == Class: zotero
#
# Zotero is a service based on running the Zotero firefox extension via xpcshell
# and javascript wrappers. It is meant to scrape URLs provided to it and return
# metadata
#
# === Parameters
#
class zotero(
    $proxy=undef,
    $proxy_port=undef) {

    package { 'xulrunner-dev':
        ensure => present,
    }

    package { [
         'zotero/translation-server',
         'zotero/translators',
        ]:
        ensure   => present,
        provider => trebuchet,
    }

    file { '/srv/deployment/zotero/translation-server/defaults/preferences/defaults.js':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('zotero/defaults.js.erb'),
    }

    group { 'zotero':
        ensure => present,
        name   => 'zotero',
        system => true,
    }

    user { 'zotero':
        gid    => 'citoid',
        home   => '/nonexistent',
        shell  => '/bin/false',
        system => true,
    }

    file { '/var/log/zotero':
        ensure => directory,
        owner  => 'zotero',
        group  => 'zotero',
        mode   => '0755',
    }

    file { '/etc/logrotate.d/zotero':
        content => template('zotero/logrotate.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    file { '/etc/init/zotero.conf':
        content => template('zotero/upstart.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    service { 'zotero':
        ensure     => running,
        hasstatus  => true,
        hasrestart => true,
        provider   => 'upstart',
    }

    Package['zotero/translation-server'] -> Service['zotero']
    Package['zotero/translators'] -> Service['zotero']
    Package['xulrunner-dev'] -> Service['zotero']
    Package['zotero/translation-server'] -> File['/srv/deployment/zotero/translation-server/defaults/preferences/defaults.js']
    Group['zotero'] -> User['zotero'] -> File['/var/log/zotero']
    File['/var/log/zotero'] -> Service['zotero']
    File['/etc/init/zotero.conf'] ~> Service['zotero']
}
