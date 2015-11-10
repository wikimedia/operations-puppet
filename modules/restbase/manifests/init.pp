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
# [*mathoid_uri*]
#   Mathoid service URI. Default: http://mathoid.svc.eqiad.wmnet:10042
# [*aqs_uri*]
#   Analytics Query Service URI. Default:
#   http://aqs.svc.eqiad.wmnet:7232/analytics.wikimedia.org/v1
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
    $parsoid_uri    = 'http://parsoid-lb.eqiad.wikimedia.org',
    $logstash_host  = 'localhost',
    $logstash_port  = 12201,
    $logging_level  = 'warn',
    $statsd_host    = 'localhost',
    $statsd_port    = '8125',
    $graphoid_uri   = 'http://graphoid.svc.eqiad.wmnet:19000',
    $mobileapps_uri = 'http://mobileapps.svc.eqiad.wmnet:8888',
    $mathoid_uri    = 'http://mathoid.svc.eqiad.wmnet:10042',
    $aqs_uri        =
    'http://aqs.svc.eqiad.wmnet:7232/analytics.wikimedia.org/v1',
    $deployment     = undef,
) {
    # TODO: remove conditional once scap deploys RESTBase everywhere
    case $deployment {
        'scap': { include restbase::deploy::scap }
        default: { include restbase::deploy::trebuchet }
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
        ensure  => absent
    }

    file { '/etc/init.d/restbase':
        ensure  => absent
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

    base::service_unit { 'restbase':
        ensure        => present,
        template_name => 'restbase',
        systemd       => true,
        refresh       => false,
        require       => [File['/etc/restbase/config.yaml'],
                          Package['restbase/deploy']],
    }
}
