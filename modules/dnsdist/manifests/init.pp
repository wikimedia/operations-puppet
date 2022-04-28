# == Class: dnsdist
#
# Install and configure dnsdist with DNS-over-HTTPS and DNS-over-TLS support.
#
# This class configures a dnsdist installation to act as a DoH and DoT resolver
# with a single backend recursor. It sets up a basic configuration to run a
# public DoH/DoT service with safe secure defaults but without any UDP support.
#
# == Parameters:
#
#  [*resolver*]
#    [Dnsdist::Resolver] downstream recursive resolver options. required.
#
#  [*tls_common*]
#    [Dnsdist::TLS_common] Common TLS configuration (certificates). required.
#
#  [*tls_config_doh*]
#    [Dnsdist::TLS_config] TLS configuration for DoH. required.
#
#  [*tls_config_dot*]
#    [Dnsdist::TLS_config] TLS configuration for DoT. required.
#
#  [*enable_wikidough*]
#    [bool] whether Wikidough-specific settings are enabled. default: true.
#
#  [*doh_paths*]
#    [array] URL paths to accept queries on. default: /, /dns-query.
#
#  [*enable_packetcache*]
#    [bool] whether to enable dnsdist's packet cache. default: true.
#
#  [*packetcache_max*]
#    [int] maximum number of entries in the cache. default: 10,000,000.
#
#  [*ringbuffer_max*]
#    [int] maximum number of entries in the ring buffer. default: 10.
#
#  [*tcp_client_threads_max*]
#    [int] maximum number of TCP client threads. default: 20.
#
#  [*enable_console*]
#    [bool] whether to enable dnsdist's console. default: false.
#
#  [*console_key*]
#    [string] key to use for dnsdist's console access. default: undef.
#
#  [*enable_webserver*]
#    [bool] whether to enable dnsdist's web server. default: false.
#
#  [*drop_querytype_any*]
#    [bool] whether to drop queries with qtype=ANY. default: true.
#
#  [*webserver*]
#    [Dnsdist::Webserver_config] web server configuration. default: undef.
#
#  [*enable_ecs*]
#    [bool] whether to enable EDNS Client Subnet. default: true.
#
#  [*enable_landing*]
#    [bool] whether to enable the landing page (/). default: false.
#
#  [*landing_text*]
#    [string] text on the landing page. default: undef.
#
#  [*custom_headers*]
#    [Dnsdist::Http_headers] custom HTTP headers. default: {}.


class dnsdist (
    Dnsdist::Resolver                   $resolver,
    Dnsdist::TLS_common                 $tls_common,
    Dnsdist::TLS_config                 $tls_config_doh,
    Dnsdist::TLS_config                 $tls_config_dot,
    Boolean                             $enable_wikidough       = true,
    Array[String[1]]                    $doh_paths              = ['/', '/dns-query'],
    Boolean                             $enable_qps_max         = false,
    Integer[1]                          $qps_max                = 40,
    Boolean                             $enable_packetcache     = true,
    Integer[1]                          $packetcache_max        = 10000000,
    Integer[1]                          $ringbuffer_max         = 10,
    Integer[1]                          $tcp_client_threads_max = 20,
    Boolean                             $enable_console         = false,
    Optional[String]                    $console_key            = undef,
    Boolean                             $enable_webserver       = false,
    Boolean                             $drop_querytype_any     = true,
    Optional[Dnsdist::Webserver_config] $webserver              = undef,
    Boolean                             $enable_ecs             = true,
    Boolean                             $enable_landing         = false,
    Optional[String]                    $landing_text           = undef,
    Dnsdist::Http_headers               $custom_headers         = {},
) {

    if ($enable_console and $console_key == undef) {
        fail('Console access is enabled but no key was set.')
    }

    if ($enable_webserver and $webserver == undef) {
        fail('Web server access is enabled but no configuration was set.')
    }

    apt::package_from_component { 'dnsdist':
        component => 'component/dnsdist',
    }

    file { '/etc/dnsdist/dnsdist.conf':
        ensure       => 'present',
        require      => Package['dnsdist'],
        owner        => 'root',
        group        => '_dnsdist',
        mode         => '0440',
        content      => template('dnsdist/dnsdist.conf.erb'),
        validate_cmd => '/usr/bin/dnsdist --check-config --config %',
    }

    systemd::service { 'dnsdist':
        ensure         => present,
        override       => true,
        restart        => true,
        content        => template('dnsdist/dnsdist-systemd-override.conf.erb'),
        require        => [
            Package['dnsdist'],
            File['/etc/dnsdist/dnsdist.conf'],
        ],
        service_params => {
            restart => '/bin/systemctl reload dnsdist.service',
            enable  => true,
        },
    }

}
