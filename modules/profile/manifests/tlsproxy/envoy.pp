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
# TODO: allows services to override this value in the Profile::Tlsproxy::Envoy::Service Struct
# @param upstream_addr the address of the backend service.  must be a localy configuered ipaddrres,
#                      localhost or $facts['fqdn'].  Default: $facts['fqdn']
# @param services An array of Profile::Tlsproxy::Envoy::Service's to configure
#                 Default [{server_name: ['*'], port: 80}]
# @param global_cert_name The name of the certificate to install via sslcert::certificate
# @param acme_cert_name The name of the certificate to install via sslcert::certificate acme_chief::cert
# @param access_log Whether to use an access log or not.
# @param capitalize_headers Whether to capitalize headers when responding to HTTP/1.1 requests
# @param idle_timeout If indicated, that's how long an idle connection to the service is left open before closing it.
#                     It should match the idle timeout of the upstream service.
class profile::tlsproxy::envoy(
    Profile::Tlsproxy::Envoy::Sni $sni_support               = lookup('profile::tlsproxy::envoy::sni_support'),
    Stdlib::Port                  $tls_port                  = lookup('profile::tlsproxy::envoy::tls_port'),
    Boolean                       $websockets                = lookup('profile::tlsproxy::envoy::websockets'),
    Float                         $upstream_response_timeout = lookup('profile::tlsproxy::envoy::upstream_response_timeout'),
    Boolean                       $retries                   = lookup('profile::tlsproxy::envoy::retries'),
    Boolean                       $use_remote_address        = lookup('profile::tlsproxy::envoy::use_remote_address'),
    Boolean                       $access_log                = lookup('profile::tlsproxy::envoy::access_log'),
    Boolean                       $capitalize_headers        = lookup('profile::tlsproxy::envoy::capitalize_headers'),
    Boolean                       $listen_ipv6               = lookup('profile::tlsproxy::envoy::listen_ipv6'),
    Array[Profile::Tlsproxy::Envoy::Service] $services = lookup('profile::tlsproxy::envoy::services'),
    Optional[Stdlib::Host]        $upstream_addr    = lookup('profile::tlsproxy::envoy::upstream_addr'),
    Optional[String]              $global_cert_name = lookup('profile::tlsproxy::envoy::global_cert_name',
                                                      {'default_value' => undef}),
    Optional[String]              $acme_cert_name   = lookup('profile::tlsproxy::envoy::acme_cert_name',
                                                      {'default_value' => undef}),
    Optional[Float]               $idle_timeout = lookup('profile::tlsproxy::envoy::idle_timeout',
                                                      {'default_value' => undef}),
    Optional[String]              $ferm_srange  = lookup('profile::tlsproxy::envoy::ferm_srange',
                                                      {'default_value' => undef}),
    Optional[Integer]             $max_requests = lookup('profile::tlsproxy::envoy::max_requests',
                                                      {'default_value' => undef}),
) {
    require profile::envoy
    $ensure = $profile::envoy::ensure

    if $global_cert_name and $acme_cert_name {
        fail('\$global_cert_name and \$acme_chief are mutually exclusive please only provide one')
    }
    $valid_upstream_addr = $facts['networking']['interfaces'].values().reduce([]) |$memo, $int| {
        $memo + [$int['ip'], $int['ip6']]
    }.delete_undef_values() + ['localhost', $facts['fqdn']]
    unless $upstream_addr in $valid_upstream_addr {
        fail("upstream_addr must be one of: ${valid_upstream_addr.join(', ')}")
    }

    # ensure all the needed certs are present. Given these are internal services,
    # we want certs declared with the traditional sslcert for now.
    $services.each |$service| {
        $certname = $service['cert_name']
        if $service['cert_name'] {
            sslcert::certificate { $service['cert_name']:
                ensure => $ensure,
                group  => 'envoy',
                notify => Service['envoyproxy.service'],
            }
        }
    }
    $upstreams = $services.map |$service| {
        $certname = $service['cert_name']
        if $certname and $sni_support != 'no' {
            $cert = "/etc/ssl/localcerts/${service['cert_name']}.crt"
            $key = "/etc/ssl/private/${service['cert_name']}.key"
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
        if $global_cert_name {
            sslcert::certificate { $global_cert_name:
                ensure => $ensure,
                group  => 'envoy',
                notify => Service['envoyproxy.service'],
            }
            $global_cert_path = "/etc/ssl/localcerts/${global_cert_name}.crt"
            $global_key_path = "/etc/ssl/private/${global_cert_name}.key"
        } elsif $acme_cert_name {
            acme_chief::cert {$acme_cert_name:
                puppet_svc => 'envoyproxy.service',
                key_group  => 'envoy',
            }
            $global_cert_path = "/etc/acmecerts/${acme_cert_name}/live/ec-prime256v1.chained.crt"
            $global_key_path = "/etc/acmecerts/${acme_cert_name}/live/ec-prime256v1.key"
        } else {
            fail(['If you want non-sni TLS to be supported, you need to define ',
                  'profile::tlsproxy::envoy::global_cert_name or ',
                  'profile::tlsproxy::envoy::acme_cert_name'].join(' '))
        }
    }

    if $ensure == 'present' {
        if $retries {
            # Use the default envoy retry policy
            $retry_policy = undef
        } else {
            $retry_policy = {'num_retries' => 0}
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
        }
        ferm::service { 'envoy_tls_termination':
            proto   => 'tcp',
            notrack => true,
            port    => $tls_port,
            srange  => $ferm_srange,
        }
    }
}
