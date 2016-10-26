class docker::registry::web(
    $docker_username,
    $docker_password_hash,
    $allow_push_from,
    $ssl_certificate_name,
    $ssl_settings,
) {
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
