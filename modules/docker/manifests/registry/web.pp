class docker::registry::web(
    $docker_username,
    $docker_password_hash,
    $allow_push_from,
    $ssl_settings,
    $use_puppet_certs=false,
    $ssl_certificate_name=undef,
) {
    if !$use_puppet_certs and !defined($ssl_certificate_name) {
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
        content => template('docker/registry-nginx.conf.erb'),
    }

}
