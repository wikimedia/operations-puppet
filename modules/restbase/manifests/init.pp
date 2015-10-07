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
# [*cassandra_localDc*]
#   Which DC should be considered local. Default: 'datacenter1'.
# [*cassandra_datacenters*]
#   The full list of member datacenters.
# [*port*]
#   Port where to run the restbase service. Default: 7231
# [*config_template*]
#   File to use as the configuration file template. Default: restbase/config.yaml.erb
# [*parsoid_uri*]
#   URI to reach Parsoid. Default: http://parsoid-lb.eqiad.wikimedia.org
# [*logstash_host*]
#   GELF logging host. Default: localhost
# [*logstash_port*]
#   GELF logging port. Default: 12201
# [*logging_level*]
#   The logging level. One of ['trace','debug','info','warn','error','fatal']
#   Default: 'warn'
# [*statsd_host*]
#   statsd host name. Default: localhost
# [*statsd_port*]
#   statsd port. Default: 8125
# [*graphoid_uri*]
#   graphoid host + port. Default: http://graphoid.svc.eqiad.wmnet:19000
# [*mobileapps_uri*]
#   MobileApps service URI. Default: http://mobileapps.svc.eqiad.wmnet:8888
#
class restbase(
    $cassandra_user = 'cassandra',
    $cassandra_password = 'cassandra',
    $seeds          = [$::ipaddress],
    $cassandra_defaultConsistency = 'localQuorum',
    $cassandra_localDc = 'datacenter1',
    $cassandra_datacenters = [ 'datacenter1' ],
    $port           = 7231,
    $salt_key       = 'secretkey',
    $page_size      = 250,
    $config_template = 'restbase/config.yaml.erb',
    $parsoid_uri    = 'http://parsoid-lb.eqiad.wikimedia.org',
    $logstash_host  = 'localhost',
    $logstash_port  = 12201,
    $logging_level  = 'warn',
    $statsd_host    = 'localhost',
    $statsd_port    = '8125',
    $graphoid_uri   = 'http://graphoid.svc.eqiad.wmnet:19000',
    $mobileapps_uri = 'http://mobileapps.svc.eqiad.wmnet:8888',
) {
    if $::realm == 'labs' {
        include restbase::deploy
    }

    package { 'restbase/deploy':
        provider => 'trebuchet',
    }

    require_package('nodejs')
    require_package('nodejs-legacy')
    require_package('npm')

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
    }

    file { '/etc/init.d/restbase':
        content => template('restbase/restbase.init'),
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        require => File['/etc/default/restbase'],
    }

    file { '/etc/restbase':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        before => Service['restbase'],
    }

    file { '/etc/restbase/config.yaml':
        content => template($config_template),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        tag     => 'restbase::config',
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
        require    => File[
            '/etc/restbase/config.yaml',
            '/etc/init.d/restbase'
        ],
    }
}
