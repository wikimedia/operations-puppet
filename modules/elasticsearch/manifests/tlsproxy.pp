# = Define: elasticsearch::tlsproxy
#
# This class configures a https proxy to a local http service
#
# == Parameters:
# [*certificate_name*]
#   name that will be checked in the SSL certificate. This should probably
#   match the value configured in `base::puppet::dns_alt_names` if it is set,
#   unless the service is accessed directly by FQDN.
#
# [*http_port*]
#   local http port to proxy requests to
#
# [*tls_port*]
#  port to expose tls on
#
define elasticsearch::tlsproxy (
    Stdlib::Port $upstream_port,
    Stdlib::Port $tls_port,
    Array[String] $certificate_names = [],
    Boolean $acme_chief = false,
    Optional[String] $acme_certname = undef,
    String $server_name = $::fqdn,
    String $ocsp_proxy = undef,
){
    tlsproxy::localssl { $title:
        certs          => $certificate_names,
        server_name    => $server_name,
        default_server => true,
        acme_chief     => $acme_chief,
        acme_certname  => $acme_certname,
        upstream_ports => [$upstream_port],
        tls_port       => $tls_port,
        ocsp_proxy     => $ocsp_proxy,
    } -> monitoring::service { "elasticsearch-https-${title}":
        ensure        => present,
        description   => "Elasticsearch HTTPS for ${title}",
        check_command => "check_ssl_on_port!${server_name}!${tls_port}",
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Search',
    }
}
