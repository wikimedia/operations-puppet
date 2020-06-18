# == Class: dnsdist
#
# Install and configure dnsdist.
#
# == Parameters:
#
#  [*resolver*]
#    [Dnsdist::Resolver] downstream recursive resolver options. required.
#
#  [*tls_config*]
#    [Dnsdist::TLS_config] TLS configuration. required.
#
#  [*doh_base_url*]
#    [string] URL to accept DoH queries on. default: /dns-query.
#
#  [*qps_max*]
#    [int] maximum number of queries allowed per second from an IP. default: 10.
#
#  [*enable_packetcache*]
#    [bool] whether to enable dnsdist's packet cache. default: true.
#
#  [*packetcache_max*]
#    [int] maximum number of entries in the cache. default: 10,000,000.
#
#  [*enable_console*]
#    [bool] whether to enable dnsdist's console. default: true.
#
#  [*console_key*]
#    [string] key to use for dnsdist's console access. default: undefined.
#
#  [*enable_webserver*]
#    [bool] whether to enable dnsdist's web server. default: false.
#
#  [*webserver_config*]
#    [Dnsdist::Webserver_config] web server configuration. default: undef.

class dnsdist (
    Dnsdist::Resolver                   $resolver,
    Dnsdist::TLS_config                 $tls_config,
    String                              $doh_base_url       = '/dns-query',
    Integer[1]                          $qps_max            = 20,
    Boolean                             $enable_packetcache = true,
    Integer[1]                          $packetcache_max    = 10000000,
    Boolean                             $enable_console     = true,
    Optional[String]                    $console_key        = undef,
    Boolean                             $enable_webserver   = false,
    Optional[Dnsdist::Webserver_config] $webserver_config   = undef,
) {

    if ($enable_console and $console_key == undef) {
        fail('Console access is enabled but no key was set.')
    }

    if ($enable_webserver and $webserver_config == undef) {
        fail('Web server access is enabled but no configuration was set.')
    }

    apt::package_from_component { 'dnsdist':
        component => 'component/dnsdist',
    }

    file { '/etc/dnsdist/dnsdist.conf':
        ensure  => 'present',
        require => Package['dnsdist'],
        owner   => 'root',
        group   => 'root',
        mode    => '0440',
        content => template('dnsdist/dnsdist.conf.erb'),
        notify  => Service['dnsdist'],
    }

    service { 'dnsdist':
        ensure     => 'running',
        require    => Package['dnsdist'],
        hasrestart => true,
    }

}
