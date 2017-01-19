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
# [*ferm_srange*]
#   The network range that should be allowed access to elasticsearch. This
#   needs to be customized for elasticsearch clusters serving non production
#   traffic. The relforge cluster is an example.
#   Default: $DOMAIN_NETWORKS
#
class elasticsearch::https (
    $ensure           = present,
    $certificate_name = $::fqdn,
    $ferm_srange      = '$DOMAIN_NETWORKS',
){

    if $ensure == present {
        validate_string($certificate_name)
    }

    class { [ 'nginx', 'nginx::ssl' ]:
        ensure => $ensure,
    }

    diamond::collector::nginx { 'elasticsearch':
        ensure => $ensure,
    }

    ::base::expose_puppet_certs { '/etc/nginx':
        ensure          => $ensure,
        provide_private => true,
        require         => Class['nginx'],
    }

    ::nginx::site { 'elasticsearch-ssl-termination':
        ensure  => $ensure,
        content => template('elasticsearch/nginx/es-ssl-termination.nginx.conf.erb'),
    } -> ::monitoring::service { 'elasticsearch-https':
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
