# == Class: restbase
#
# restbase is a REST API & storage service
# http://restbase.org
#
# === Parameters
#
# [*cassandra_user*]
#   Cassandra user name.
# [*cassandra_password*]
#   Cassandra password.
# [*seeds*]
#   Array of cassandra hosts (IP or host names) to contact.
#   Default: ['localhost']
# [*cassandra_defaultConsistency*]
#   Default cassandra query consistency level. Typically 'one' or
#   'localQuorum'. Default: 'localQuorum'.
# [*port*]
#   Port where to run the restbase service. Default: 7231
# [*logstash_host*]
#   GELF logging host. Default: localhost
# [*logstash_port*]
#   GELF logging port. Default: 12201
# [*statsd_host*]
#   statsd host name. Default: localhost
#
class restbase(
    $cassandra_user = 'cassandra',
    $cassandra_password = 'cassandra',
    $seeds          = [$::ipaddress],
    $cassandra_defaultConsistency = 'localQuorum',
    $port           = 7231,
    $logstash_host  = 'localhost',
    $logstash_port  = 12201,
    $statsd_host    = 'localhost',
) {
    ensure_packages( ['nodejs', 'nodejs-legacy', 'npm'] )

    package { 'restbase/deploy':
        provider => 'trebuchet',
    }

    group { 'restbase':
        ensure => present,
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
        mode   => '0755',
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
        mode    => '0755',
        notify  => Service['restbase'],
    }

    file { '/etc/restbase':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        before => Service['restbase'],
    }

    file { '/etc/restbase/config.yaml':
        content => template('restbase/config.yaml.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['restbase'],
    }

    file { '/usr/lib/restbase':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        before => Service['restbase'],
    }

    file { '/usr/lib/restbase/deploy':
        ensure  => link,
        target  => '/srv/deployment/restbase/deploy',
        require => File['/usr/lib/restbase'],
        before  => Service['restbase'],
    }

    service { 'restbase':
        ensure     => running,
        hasstatus  => true,
        hasrestart => true,
        provider   => 'init',
    }
}
