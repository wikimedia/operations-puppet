class docker_registry_ha::web (
    String $docker_username,
    String $docker_password_hash,
    Array[Stdlib::Host] $allow_push_from,
    Array[String] $ssl_settings,
    Boolean $use_puppet_certs=false,
    Optional[String] $ssl_certificate_name=undef,
    Boolean $http_endpoint=false,
    Array[Stdlib::Host] $http_allowed_hosts=[],
    Boolean $read_only_mode=false,
    String $homepage='/srv/homepage',
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

    ensure_packages(['python3-docker-report'])

    file { '/usr/local/bin/registry-homepage-builder':
        mode    => '0744',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/docker_registry_ha/registry-homepage-builder.py',
        require => Package['python3-docker-report'],
    }

    file { '/usr/local/lib/registry-homepage-builder.css':
        mode   => '0644',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/docker_registry_ha/style.css',
    }

    file { $homepage:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    # Spread out jobs so they don't all run at the same time, leading to 504s from the registry
    $minute = Integer(seeded_rand(60, "${::fqdn}-build-homepage"))
    systemd::timer::job {'build-homepage':
        ensure      => 'present',
        description => 'Build docker-registry homepage',
        command     => "/usr/local/bin/registry-homepage-builder localhost:5000 ${homepage}",
        user        => 'root',
        interval    => {
            'start'    => 'OnCalendar',
            'interval' => "*-*-* *:${minute}:00", # every hour
        },
        require     => File['/usr/local/bin/registry-homepage-builder'],
    }
}
