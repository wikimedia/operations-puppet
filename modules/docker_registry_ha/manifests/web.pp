class docker_registry_ha::web (
    String $docker_username,
    String $docker_password_hash,
    Array[Stdlib::Host] $allow_push_from,
    Array[String] $ssl_settings,
    Boolean $use_puppet_certs=false,
    Optional[String] $ssl_certificate_name=undef,
    Boolean $http_endpoint=false,
    Array[Stdlib::Host] $http_allowed_hosts=[],
) {
    if (!$use_puppet_certs and ($ssl_certificate_name == undef)) {
        fail('Either puppet certs should be used, or an ssl cert name should be provided')
    }

    if $use_puppet_certs {
        base::expose_puppet_certs { '/etc/nginx':
            ensure          => present,
            provide_private => true,
            require         => Class['nginx'],
        }
    }

    file { '/etc/nginx/htpasswd.registry':
        content => "${docker_username}:${docker_password_hash}",
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '0440',
        before  => Service['nginx'],
        require => Package['nginx-common'],
    }
    nginx::site { 'registry':
        content => template('docker_registry_ha/registry-nginx.conf.erb'),
    }

    if $http_endpoint {
        nginx::site { 'registry-http':
            content => template('docker_registry_ha/registry-http-nginx.conf.erb'),
        }
    }

}
