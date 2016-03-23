# = Class: elasticsearch::https
#
# This class configures HTTPS for elasticsearch
#
# == Parameters:
# [*ensure*]
#   self explanatory
#
# [*certificate_name*]
#   name that will be checked in the SSL certificate. This should match the
#   value configured in `base::puppet::dns_alt_names`

class elasticsearch::https (
    $ensure          = absent,
    $certificate_name = 'search.svc.codfw.wmnet',
){

    class { [ 'nginx', 'nginx::ssl' ]:
        ensure => $ensure,
    }

    diamond::collector::nginx { 'elasticsearch':
        ensure => $ensure,
    }

    ::base::expose_puppet_certs { '/etc/nginx':
        ensure          => $ensure,
        provide_private => true,
    }

    ::nginx::site { 'elasticsearch-ssl-termination':
        ensure  => $ensure,
        content => template('elasticsearch/nginx/es-ssl-termination.nginx.conf.erb'),
    } -> ::monitoring::service { 'elasticsearch-https':
        description   => 'Elasticsearch HTTPS',
        check_command => "check_ssl_http!${certificate_name}",
    }

    ::ferm::service { 'elastic-https':
        ensure => $ensure,
        proto  => 'tcp',
        port   => '9243',
        srange => '$INTERNAL',
    }

}
