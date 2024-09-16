# SPDX-License-Identifier: Apache-2.0
# == Class profile::tlsproxy::envoy
#
# Sets up TLS termination using the envoy proxy.
#
# === Examples
# Example hiera setups for common use-cases.
#
# Set up a global TLS proxy to apache listening on TCP port 444.
#   profile::envoy::ensure: present
#   profile::tlsproxy::envoy::sni_support: "no" # you need the double quotes, because yaml.
#   profile::tlsproxy::envoy::tls_port: 444
#   profile::tlsproxy::envoy::services:
#      - server_names: ['*']
#        port: 80
#   profile::tlsproxy::envoy::global_cert_name: "appserver"
#
# Set up a TLS proxy to multiple backend services, with sni support
# The "virtual host" for '*.test' doesn't have a cert_name, so it will
# only be served with the global certificate.
#
#   profile::envoy::ensure: present
#   profile::tlsproxy::envoy::sni_support: yes
#   profile::tlsproxy::envoy::services:
#      - server_names: ['service1', '*.service1.production']
#        port: 8080
#        cert_name: 'service1'
#      - server_names: ['service2', '*.service2.production']
#        port: 8081
#        cert_name: 'service2'
#      - server_names: ['*.test']
#        port: 9999
#   profile::tlsproxy::envoy::global_cert_name: "appserver"
#
# Retries and timeouts can be defined if needed. By default we will have:
# - 65 seconds timeout on requests
# - 1 retry on error
# @param sni_support use one of yes, no, or strict to indicate sni behaviour.  Default: yes
# @param tls_port The TLS port to listen on.  Default 443
# @param websockets If true configure websocket support.  Default: false
# @param upstream_response_timeout timeout on a request in seconds.  Default: 65
# @param retries If true enable retries. Default: true
# @param use_remote_address If true append the client address to the x-forwarded-for header
# @param ssl_provider the ssl provider e.g. sslcert, acme_chief
# TODO: allows services to override this value in the Profile::Tlsproxy::Envoy::Service Struct
# @param upstream_addr the address of the backend service.  must be a localy configuered ipaddrres,
#                      localhost or $facts['fqdn'].  Default: $facts['fqdn']
# @param services An array of Profile::Tlsproxy::Envoy::Service's to configure
#                 Default [{server_name: ['*'], port: 80}]
# @param global_cert_name The use of this certificate depends on the value of ssl_provider.
#   when ssl_provider is sslcert this value is passed to sslcert::certificate { $global_cert_name: }
#   when ssl_provider is acme this value is passed to acme_chief::cert {$global_cert_name: }
#   when ssl_provider is cfssl this value is passed to profile::pki::get_cert($cfssl_label, $global_cert_name, ...)
# @param access_log Whether to use an access log or not.
# @param header_key_format Allows capitalizing headers or maintain the original headers case on HTTP/1.1 requests
# @param idle_timeout If indicated, that's how long an idle connection to the service is left open before closing it.
#                     It should match the idle timeout of the upstream service.
# @param stream_idle_timeout If set, set the stream idle timeout (otherwise, 5 minutes is what envoy defaults to)
# @param cfssl_label if using cfssl this parameter is mandatory and should specify the CA label sign CSR's
# @param downstream_idle_timeout Idle timeout for downstream connections
# @param upstream_idle_timeout Idle timeout for upstream connections
# @param error_page  boolean true if an error page should be added; false by default.
# @param local_otel_reporting_pct float, the percentage (e.g. 37.5) of traffic to be sampled for tracing
class profile::tlsproxy::envoy(
    Profile::Tlsproxy::Envoy::Sni    $sni_support               = lookup('profile::tlsproxy::envoy::sni_support'),
    Stdlib::Port                     $tls_port                  = lookup('profile::tlsproxy::envoy::tls_port'),
    Boolean                          $websockets                = lookup('profile::tlsproxy::envoy::websockets'),
    Float                            $upstream_response_timeout = lookup('profile::tlsproxy::envoy::upstream_response_timeout'),
    Boolean                          $retries                   = lookup('profile::tlsproxy::envoy::retries'),
    Boolean                          $use_remote_address        = lookup('profile::tlsproxy::envoy::use_remote_address'),
    Boolean                          $access_log                = lookup('profile::tlsproxy::envoy::access_log'),
    Envoyproxy::Headerkeyformat      $header_key_format         = lookup('profile::tlsproxy::envoy::header_key_format'),
    Boolean                          $listen_ipv6               = lookup('profile::tlsproxy::envoy::listen_ipv6'),
    Enum['sslcert', 'acme', 'cfssl'] $ssl_provider              = lookup('profile::tlsproxy::envoy::ssl_provider'),
    Hash                             $cfssl_options             = lookup('profile::tlsproxy::envoy::cfssl_options'),
    Array[Profile::Tlsproxy::Envoy::Service] $services          = lookup('profile::tlsproxy::envoy::services'),
    Optional[Stdlib::Host]           $upstream_addr             = lookup('profile::tlsproxy::envoy::upstream_addr'),
    Optional[String]                 $global_cert_name          = lookup('profile::tlsproxy::envoy::global_cert_name'),
    Optional[Float]                  $idle_timeout              = lookup('profile::tlsproxy::envoy::idle_timeout'),
    Optional[Float]                  $stream_idle_timeout       = lookup('profile::tlsproxy::envoy::stream_idle_timeout'),
    Optional[String]                 $ferm_srange               = lookup('profile::tlsproxy::envoy::ferm_srange'),
    Optional[Firewall::Range]        $firewall_srange           = lookup('profile::tlsproxy::envoy::firewall_srange'),
    Optional[Integer]                $max_requests              = lookup('profile::tlsproxy::envoy::max_requests'),
    Optional[String]                 $cfssl_label               = lookup('profile::tlsproxy::envoy::cfssl_label'),
    Optional[Float]                  $upstream_idle_timeout     = lookup('profile::tlsproxy::envoy::upstream_idle_timeout'),
    Optional[Float]                  $downstream_idle_timeout   = lookup('profile::tlsproxy::envoy::downstream_idle_timeout'),
    Boolean                          $error_page                = lookup('profile::tlsproxy::envoy::error_page'),
    Float                            $local_otel_reporting_pct  = lookup('profile::tlsproxy::envoy::local_otel_reporting_pct'),
) {
    require profile::envoy
    $ensure = $profile::envoy::ensure

    $valid_upstream_addr = $facts['networking']['interfaces'].values().reduce([]) |$memo, $int| {
        $memo + [$int['ip'], $int['ip6']]
    }.delete_undef_values() + ['localhost', $facts['fqdn']]
    unless $upstream_addr in $valid_upstream_addr {
        fail("upstream_addr must be one of: ${valid_upstream_addr.join(', ')}")
    }
    if $ssl_provider == 'cfssl' and !$cfssl_label {
        fail('must specify \$cfssl_label when using ssl_provider: cfssl')
    }

    # By default use the server profile
    $base_cfssl_options = {
        'profile' => 'server',
        'ensure'  => stdlib::ensure($ensure),
        'owner'   => 'envoy',
        'group'   => 'envoy',
        'outdir'  => '/etc/envoy/ssl',
        'notify'  => Service['envoyproxy.service'],
        'require' => Package['envoyproxy'],
    }
    $upstreams = $services.map |$service| {
        if $service['cert_name'] and $sni_support != 'no' {
            # ensure all the needed certs are present. Given these are internal services,
            # we want certs declared with the traditional sslcert for now.
            case $ssl_provider {
                'sslcert': {
                    sslcert::certificate { $service['cert_name']:
                        ensure => $ensure,
                        group  => 'envoy',
                        notify => Service['envoyproxy.service'],
                    }
                    $certificates = [{
                        'cert_path' => "/etc/ssl/localcerts/${service['cert_name']}.crt",
                        'key_path'  => "/etc/ssl/private/${service['cert_name']}.key",
                    }]
                }
                'acme': {
                    acme_chief::cert { $service['cert_name']:
                        puppet_svc => 'envoyproxy.service',
                        key_group  => 'envoy',
                    }
                    $certificates = [{
                        'cert_path' => "/etc/acmecerts/${service['cert_name']}/live/ec-prime256v1.chained.crt",
                        'key_path'  => "/etc/acmecerts/${service['cert_name']}/live/ec-prime256v1.key",
                    }]
                }
                'cfssl': {
                    $cfssl_base_options = $base_cfssl_options + {'hosts' =>  $service['server_names']}
                    $_cfssl_options = $service['cfssl_options'] ? {
                        undef   => $cfssl_base_options,
                        default => $cfssl_base_options + $service['cfssl_options'],
                    }
                    $_cfssl_label = $service['cfssl_label'] ? {
                        undef   => $cfssl_label,
                        default => $service['cert_label'],
                    }
                    $ssl_paths = profile::pki::get_cert($_cfssl_label, $service['cert_name'], $_cfssl_options)
                    $certificates = [{
                        'cert_path' => $ssl_paths['chained'],
                        'key_path'  => $ssl_paths['key'],
                    }]
                }
                default: {
                    # shouldn't ever reach here
                    fail("ssl_provider (${ssl_provider}) unsupported")
                }
            }
        } else {
            $certificates = undef
        }
        # This is the variable that's returned to the map.
        $upstream = {
            'server_names'  => $service['server_names'],
            'certificates'  => $certificates,
            'upstream'      => {'port' => $service['port'], 'addr' => $upstream_addr},
        }
    }

    if $sni_support == 'strict' {
        $global_certs = undef
    }
    else {
        unless $global_cert_name {
            fail(['If you want non-sni TLS to be supported, you need to define ',
                  'profile::tlsproxy::envoy::global_cert_name or '].join(' '))
        }
        case $ssl_provider {
            'sslcert': {
                sslcert::certificate { $global_cert_name:
                    ensure => $ensure,
                    group  => 'envoy',
                    notify => Service['envoyproxy.service'],
                }
                $global_certs = [{
                    'cert_path' => "/etc/ssl/localcerts/${global_cert_name}.crt",
                    'key_path'  => "/etc/ssl/private/${global_cert_name}.key",
                }]
            }
            'acme': {
                acme_chief::cert {$global_cert_name:
                    puppet_svc => 'envoyproxy.service',
                    key_group  => 'envoy',
                }
                $global_certs = [{
                    'cert_path' => "/etc/acmecerts/${global_cert_name}/live/ec-prime256v1.chained.crt",
                    'key_path'  => "/etc/acmecerts/${global_cert_name}/live/ec-prime256v1.key",
                }]
            }
            'cfssl': {
                $ssl_paths = profile::pki::get_cert(
                    $cfssl_label, $global_cert_name, $base_cfssl_options + $cfssl_options
                )
                $global_certs = [{
                    'cert_path' => $ssl_paths['chained'],
                    'key_path'  => $ssl_paths['key'],
                }]
            }
            default: {
                # shouldn't ever reach here
                fail("ssl_provider (${ssl_provider}) unsupported")
            }
        }
    }

    if $ensure == 'present' {

        $retry_policy = $retries ? {
            true    => undef,
            default => {'num_retries' => 0},
        }

        if $error_page {
            # TODO: add ensure to mediawiki::errorpage
            mediawiki::errorpage { '/etc/envoy/error_page.html':
                owner      => 'envoy',
                group      => 'envoy',
                footer     => '<p>Original error: %LOCAL_REPLY_BODY% </p>',
                before     => Service['envoyproxy.service'],
                margin     => '7vh auto 0 auto', # Envoy can't accept % signs in its string formats AFAICS
                margin_top => '14vh'
            }
        }

        envoyproxy::tls_terminator{ "${tls_port}": # lint:ignore:only_variable_string
            upstreams                 => $upstreams,
            access_log                => $access_log,
            websockets                => $websockets,
            fast_open_queue           => 150,
            global_certs              => $global_certs,
            retry_policy              => $retry_policy,
            upstream_response_timeout => $upstream_response_timeout,
            use_remote_address        => $use_remote_address,
            header_key_format         => $header_key_format,
            listen_ipv6               => $listen_ipv6,
            idle_timeout              => $idle_timeout,
            stream_idle_timeout       => $stream_idle_timeout,
            max_requests_per_conn     => $max_requests,
            has_error_page            => $error_page,
            local_otel_reporting_pct  => $local_otel_reporting_pct,
            upstream_idle_timeout     => $upstream_idle_timeout,
            downstream_idle_timeout   => $downstream_idle_timeout,
        }

        if $local_otel_reporting_pct > 0 {
            # TLS terminator was defined with OpenTelemetry reporting enabled.
            $upstream_name = 'otel-collector'
            if !defined(Envoyproxy::Cluster["cluster_${upstream_name}"]) {
                # Set an upstream cluster that is required by the tracing stanza
                $max_requests_per_conn = $max_requests
                $connect_timeout = 1.0
                $upstream = {
                    'upstream' => {'port' => 4317, 'addr' => '127.0.0.1'},
                }
                envoyproxy::cluster { "cluster_${upstream_name}":
                  priority => 1,
                  content  => template('envoyproxy/tracing_cluster.yaml.erb'),
                }
            }
        }

        # If $firewall_srange is configured for a service, don't populate the service
        # based on the $ferm_srange
        # We check for NotUndef here as an empty list (which is false'y) is valid
        if $firewall_srange =~ NotUndef {
            if $firewall_srange == [] {
                firewall::service { 'envoy_tls_termination':
                    proto   => 'tcp',
                    notrack => true,
                    port    => $tls_port,
                }
            } else {
                firewall::service { 'envoy_tls_termination':
                    proto   => 'tcp',
                    notrack => true,
                    port    => $tls_port,
                    srange  => $firewall_srange,
                }
            }
        } else {
            ferm::service { 'envoy_tls_termination':
                proto   => 'tcp',
                notrack => true,
                port    => $tls_port,
                srange  => $ferm_srange,
            }
        }
    }
}
