# == Class: dnsdist
#
# Install and configure dnsdist.
#
# == Parameters:
#
#  [*resolvers*]
#    [hash] downstream recursive resolvers to their configuration. required.
#
#  [*tls_config*]
#    [Dnsdist::TLS_config] TLS configuration settings. see types/tls_config.
#
#  [*doh_base_url*]
#    [string] URL to accept DoH queries on. default: /dns-query.
#
#  [*qps_max*]
#    [int] maximum number of queries allowed per second from an IP. default: 10.
#
#  [*packetcache*]
#    [bool] whether to use dnsdist's packet cache. default: true.
#
#  [*packetcache_max*]
#    [int] maximum number of entries in the cache. default: 10,000,000.

class dnsdist (
    Hash[String, Dnsdist::Resolver] $resolvers,
    Dnsdist::TLS_config             $tls_config,
    String                          $doh_base_url    = '/dns-query',
    Integer[1]                      $qps_max         = 10,
    Boolean                         $packetcache     = true,
    Integer[1]                      $packetcache_max = 10000000,
) {

    apt::package_from_component { 'dnsdist':
        component => 'component/dnsdist',
    }

    file { '/etc/dnsdist/dnsdist.conf':
        ensure  => 'present',
        require => Package['dnsdist'],
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('dnsdist/dnsdist.conf.erb'),
        notify  => Service['dnsdist'],
    }

    service { 'dnsdist':
        ensure     => 'running',
        require    => Package['dnsdist'],
        hasrestart => true,
    }

}
