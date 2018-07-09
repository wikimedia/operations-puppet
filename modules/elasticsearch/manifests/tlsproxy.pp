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
    String $certificate_name,
    Wmflib::IpPort $upstream_port,
    Wmflib::IpPort $tls_port,
){
    tlsproxy::localssl { $certificate_name:
        certs          => [$certificate_name],
        server_name    => $certificate_name,
        default_server => true,
        upstream_ports => [$upstream_port],
        tls_port       => $tls_port,
    } -> monitoring::service { "elasticsearch-https-${certificate_name}":
        ensure        => present,
        description   => "Elasticsearch HTTPS for ${certificate_name}",
        check_command => "check_ssl_on_port!${certificate_name}!${tls_port}",
    }
}
