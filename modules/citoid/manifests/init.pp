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
# [*statsd_host*]
#   StatsD host. Optional.
#
# [*statsd_port*]
#   StatsD port. Defaults to 8125.
#
# [*logstash_host*]
#   GELF logging host. Default: localhost
#
# [*logstash_port*]
#   GELF logging port. Default: 12201
#
class citoid(
    $port           = 1970,
    $statsd_port    = 8125,
    $zotero_port    = 1969,
    $http_proxy     = undef,
    $zotero_host    = 'localhost',
    $statsd_host    = 'localhost',
    $logstash_host  = 'localhost',
    $logstash_port  = 12201,
    $local_logdir   = '/var/log/citoid',
) {

    $local_logfile = "${local_logdir}/main.log"

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
    }

    file { '/etc/citoid/config.yaml':
        ensure  => present,
        content => template('citoid/config.yaml.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => [
            Package['citoid/deploy'],
            File['/etc/citoid'],
        ],
        notify  => Service['citoid'],
    }

    file { $local_logdir:
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
        require    => Package['nodejs', 'citoid/deploy'],
    }

}
