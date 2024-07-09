# = Define: elasticsearch::tlsproxy
#
# This class configures a https proxy to a local http service
#
# == Parameters:
# [*certificate_name*]
#   name that will be checked in the SSL certificate. This should probably
#   match the value configured in `profile::puppet::agent::dns_alt_names` if it is set,
#   unless the service is accessed directly by FQDN.
#
# [*http_port*]
#   local http port to proxy requests to
#
# [*tls_port*]
#  port to expose tls on
#
define elasticsearch::tlsproxy (
    Stdlib::Port                      $upstream_port,
    Stdlib::Port                      $tls_port,
    Array[String]                     $certificate_names = [],
    Array[Stdlib::Host]               $server_aliases    = [],
    Boolean                           $acme_chief        = false,
    Optional[String]                  $acme_certname     = undef,
    String                            $server_name       = $facts['networking']['fqdn'],
    Boolean                           $read_only         = false,
    Boolean                           $enable_http2      = false,
    Hash[String[1], Stdlib::Unixpath] $cfssl_paths       = {}
) {
    # temporary change to test envoy migration, see T368950
    if $server_name =~ /relforge/ {
        $envoy_tls_port = 10000 + $tls_port
        $ssl_paths = profile::pki::get_cert('discovery', "${facts['fqdn']}-${envoy_tls_port}", {
            'owner'           => 'envoy',
            'outdir'          => '/etc/envoy/ssl',
            'hosts'           => [$facts['hostname'], $facts['fqdn']],
            'notify' => Service['envoyproxy.service'],
        })
        envoyproxy::tls_terminator { String($envoy_tls_port):
            upstreams    => [{
            server_names => ['*'],
            upstream     => {
                port => $upstream_port,
        }
    }]
}
    } else {
        tlsproxy::localssl { $title:
            server_name       => $server_name,
            server_aliases    => $server_aliases,
            default_server    => true,
            acme_chief        => $acme_chief,
            acme_certname     => $acme_certname,
            upstream_ports    => [$upstream_port],
            tls_port          => $tls_port,
            only_get_requests => $read_only,
            enable_http2      => $enable_http2,
            cfssl_paths       => $cfssl_paths,
        }
    }
    $check_command = $acme_chief ? {
        true    => 'check_ssl_on_port_letsencrypt',
        default => 'check_ssl_on_port',
    }
    monitoring::service { "elasticsearch-https-${title}":
        ensure        => present,
        description   => "Elasticsearch HTTPS for ${title}",
        check_command => "${check_command}!${server_name}!${tls_port}",
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Search',
    }
}
