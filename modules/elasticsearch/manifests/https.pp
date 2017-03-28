# = Class: elasticsearch::https
#
# This class configures HTTPS for elasticsearch
#
# == Parameters:
# [*ensure*]
#   self explanatory
#
# [*certificate_name*]
#   name that will be checked in the SSL certificate. This should probably
#   match the value configured in `base::puppet::dns_alt_names` if it is set,
#   unless the service is accessed directly by FQDN.
#
# [*server_aliases*]
#   List of server aliases, host names also served.
#
# [*ferm_srange*]
#   The network range that should be allowed access to elasticsearch. This
#   needs to be customized for elasticsearch clusters serving non production
#   traffic. The relforge cluster is an example.
#   Default: $DOMAIN_NETWORKS
#
class elasticsearch::https (
    $ensure           = present,
    $certificate_name = $::fqdn,
    $server_aliases   = [ 'search.discovery.wmnet' ],
    $ferm_srange      = '$DOMAIN_NETWORKS',
){

    if $ensure == present {
        validate_string($certificate_name)
    }

    diamond::collector::nginx { 'elasticsearch':
        ensure => $ensure,
    }

    include ::tlsproxy::nginx_bootstrap
    tlsproxy::localssl { 'elasticsearch-https':
        server_name    => $certificate_name,
        certs          => [ $certificate_name ],
        certs_active   => [ $certificate_name ],
        server_aliases => $server_aliases,
        default_server => true,
        ssl_port       => 9243,
        do_ocsp        => false,
        upstream_ports => [ 9200 ],
        access_log     => true,
    }

    ::monitoring::service { 'elasticsearch-https':
        ensure        => $ensure,
        description   => 'Elasticsearch HTTPS',
        check_command => "check_ssl_on_port!${certificate_name}!9243",
    }

    ::ferm::service { 'elastic-https':
        ensure => $ensure,
        proto  => 'tcp',
        port   => '9243',
        srange => $ferm_srange,
    }

}
