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
# @param sni_support use on of yes, no our strict to indicate sni behaviour.  Default: yes
# @param tls_port The TLS port to listen on.  Default 443
# @param websockets If true configure websocket support.  Default: false
# @param upstream_response_timeout timeout on a request in seconds.  Default: 65
# @param retries If true enable retries. Default: true
# @param use_remote_address If true append the client address to the x-forwarded-for header
# @param floc_opt_out add the Permissions-Policy: interest-cohort=() header to opt out of FLoC
# @param ssl_provider the ssl provider e.g. sslcert, acme_chief
# TODO: allows services to override this value in the Profile::Tlsproxy::Envoy::Service Struct
# @param upstream_addr the address of the backend service.  must be a localy configuered ipaddrres,
#                      localhost or $facts['fqdn'].  Default: $facts['fqdn']
# @param services An array of Profile::Tlsproxy::Envoy::Service's to configure
#                 Default [{server_name: ['*'], port: 80}]
# @param global_cert_name The name of the certificate to install via sslcert::certificate
# @param access_log Whether to use an access log or not.
# @param capitalize_headers Whether to capitalize headers when responding to HTTP/1.1 requests
# @param idle_timeout If indicated, that's how long an idle connection to the service is left open before closing it.
#                     It should match the idle timeout of the upstream service.
# @param cfssl_label if using cfssl this parameter is mandatory and should specify the CA label sign CSR's
class profile::tlsproxy::envoy(
    Profile::Tlsproxy::Envoy::Sni    $sni_support               = lookup('profile::tlsproxy::envoy::sni_support'),
    Stdlib::Port                     $tls_port                  = lookup('profile::tlsproxy::envoy::tls_port'),
    Boolean                          $websockets                = lookup('profile::tlsproxy::envoy::websockets'),
    Float                            $upstream_response_timeout = lookup('profile::tlsproxy::envoy::upstream_response_timeout'),
    Boolean                          $retries                   = lookup('profile::tlsproxy::envoy::retries'),
    Boolean                          $use_remote_address        = lookup('profile::tlsproxy::envoy::use_remote_address'),
    Boolean                          $access_log                = lookup('profile::tlsproxy::envoy::access_log'),
    Boolean                          $capitalize_headers        = lookup('profile::tlsproxy::envoy::capitalize_headers'),
    Boolean                          $listen_ipv6               = lookup('profile::tlsproxy::envoy::listen_ipv6'),
    Boolean                          $floc_opt_out              = lookup('profile::tlsproxy::envoy::floc_opt_out'),
    Enum['sslcert', 'acme', 'cfssl'] $ssl_provider              = lookup('profile::tlsproxy::envoy::ssl_provider'),
    Hash                             $cfssl_options             = lookup('profile::tlsproxy::envoy::cfssl_options'),
    Array[Profile::Tlsproxy::Envoy::Service] $services          = lookup('profile::tlsproxy::envoy::services'),
    Optional[Stdlib::Host]           $upstream_addr             = lookup('profile::tlsproxy::envoy::upstream_addr'),
    Optional[String]                 $global_cert_name          = lookup('profile::tlsproxy::envoy::global_cert_name'),
    Optional[Float]                  $idle_timeout              = lookup('profile::tlsproxy::envoy::idle_timeout'),
    Optional[String]                 $ferm_srange               = lookup('profile::tlsproxy::envoy::ferm_srange'),
    Optional[Integer]                $max_requests              = lookup('profile::tlsproxy::envoy::max_requests'),
    Optional[String]                 $cfssl_label               = lookup('profile::tlsproxy::envoy::cfssl_label'),
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
        'profile'       => 'server',
        'owner'         => 'envoy',
        'group'         => 'envoy',
        'provide_chain' => true,
        'outdir'        => '/etc/envoy/ssl',
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
                    $cert = "/etc/ssl/localcerts/${service['cert_name']}.crt"
                    $key = "/etc/ssl/private/${service['cert_name']}.key"
                }
                'acme': {
                    acme_chief::cert { $service['cert_name']:
                        puppet_svc => 'envoyproxy.service',
                        key_group  => 'envoy',
                    }
                    $cert = "/etc/acmecerts/${service['cert_name']}/live/ec-prime256v1.chained.crt"
                    $key = "/etc/acmecerts/${service['cert_name']}/live/ec-prime256v1.key"
                }
                'cfssl': {
                    $_cfssl_options = $service['cfssl_options'] ? {
                        undef   => $base_cfssl_options,
                        default => $base_cfssl_options + $service['cfssl_options'],
                    }
                    $_cfssl_label = $service['cfssl_label'] ? {
                        undef   => $cfssl_label,
                        default => $service['cert_options'],
                    }
                    $ssl_paths = profile::pki::get_cert($_cfssl_label, $service['cert_name'], $_cfssl_options)
                    $cert = $ssl_paths['cert']
                    $key = $ssl_paths['key']
                }
                default: {
                    # shouldn't ever reach here
                    fail("ssl_provider (${ssl_provider}) unsupported")
                }
            }
        } else {
            $cert = undef
            $key = undef
        }
        # This is the variable that's returned to the map.
        $upstream = {
            'server_names'  => $service['server_names'],
            'cert_path'     => $cert,
            'key_path'      => $key,
            'upstream_port' => $service['port'],
            'upstream_addr' => $upstream_addr
        }
    }

    if $sni_support == 'strict' {
        $global_cert_path = undef
        $global_key_path = undef
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
                $global_cert_path = "/etc/ssl/localcerts/${global_cert_name}.crt"
                $global_key_path = "/etc/ssl/private/${global_cert_name}.key"
            }
            'acme': {
                acme_chief::cert {$global_cert_name:
                    puppet_svc => 'envoyproxy.service',
                    key_group  => 'envoy',
                }
                $global_cert_path = "/etc/acmecerts/${global_cert_name}/live/ec-prime256v1.chained.crt"
                $global_key_path = "/etc/acmecerts/${global_cert_name}/live/ec-prime256v1.key"
            }
            'cfssl': {
                $ssl_paths = profile::pki::get_cert(
                    $cfssl_label, $global_cert_name, $base_cfssl_options + $cfssl_options
                )
                $global_cert_path = $ssl_paths['cert']
                $global_key_path = $ssl_paths['key']
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
        $response_headers_to_add = $floc_opt_out ? {
            true    => {'Permissions-Policy' => 'interest-cohort=()'},
            default => {},
        }

        envoyproxy::tls_terminator{ "${tls_port}": # lint:ignore:only_variable_string
            upstreams                 => $upstreams,
            access_log                => $access_log,
            websockets                => $websockets,
            fast_open_queue           => 150,
            global_cert_path          => $global_cert_path,
            global_key_path           => $global_key_path,
            retry_policy              => $retry_policy,
            upstream_response_timeout => $upstream_response_timeout,
            use_remote_address        => $use_remote_address,
            capitalize_headers        => $capitalize_headers,
            listen_ipv6               => $listen_ipv6,
            idle_timeout              => $idle_timeout,
            max_requests_per_conn     => $max_requests,
            response_headers_to_add   => $response_headers_to_add,
        }
        ferm::service { 'envoy_tls_termination':
            proto   => 'tcp',
            notrack => true,
            port    => $tls_port,
            srange  => $ferm_srange,
        }
    }
}
