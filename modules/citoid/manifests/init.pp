# == Class: citoid
#
# citoid is a node.js backend for citation lookups.
#
# === Parameters
#
# [*port*]
#   Port where to run the citoid service
#
# [*http_proxy*]
#   URL of the proxy to use, defaults to the one set for zotero
#
# [*zotero_host*]
#   Host of the zotero service
#
# [*zotero_port*]
#   Port of the zotero service
#
class citoid(
    $port        = undef,
    $http_proxy  = 'url-downloader.wikimedia.org:8080',
    $zotero_host = undef,
    $zotero_port = undef
) {

    include lvs::configuration
    $lvs_services = $lvs::configuration::lvs_services

    unless $port {
        $port = $lvs_services['citoid']['port']
    }
    unless $zotero_host {
        $zotero_host = $lvs_services['zotero']['host']
    }
    unless $zotero_port {
        $zotero_port = $lvs_services['zotero']['port']
    }

    require_package('nodejs')

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

    file { '/etc/citoid':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        before => Service['citoid'],
    }

    file { '/etc/citoid/localsettings.js':
        ensure  => present,
        content => template('citoid/localsettings.js.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => Package['citoid/deploy'],
        before  => Service['citoid'],
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
        require    => Package['nodejs'],
    }
}
