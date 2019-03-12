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
    Wmflib::IpPort $upstream_port,
    Wmflib::IpPort $tls_port,
    Optional[String] $certificate_name = undef,
    Optional[String] $acme_subject = undef,
){
    $certs = $certificate_name ? {
        undef   => [],
        default => [$certificate_name]
    }

    $server_name = $certificate_name ? {
        undef   => $::fqdn,
        default => $certificate_name
    }

    $acme_subjects = $acme_subject ? {
        undef   => [],
        default => [$acme_subject]
    }

    tlsproxy::localssl { $title:
        certs          => $certs,
        server_name    => $server_name,
        acme_subjects  => $acme_subjects,
        default_server => true,
        upstream_ports => [$upstream_port],
        tls_port       => $tls_port,
    } -> monitoring::service { "elasticsearch-https-${title}":
        ensure        => present,
        description   => "Elasticsearch HTTPS for ${title}",
        check_command => "check_ssl_on_port!${server_name}!${tls_port}",
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Search',
    }
}
