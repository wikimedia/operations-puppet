# Class: role::archiva
#
# Installs Apache Archiva and
# sets up a cron job to symlink .jar files to
# a git-fat store.
#
class role::archiva {
    system::role { 'role::archiva': description => 'Apache Archiva Host' }

    if !defined(Package['openjdk-7-jdk']) {
        package { 'openjdk-7-jdk':
            ensure => 'installed',
        }
    }

    $archiva_port = 8080
    class { '::archiva':
        port    => $archiva_port,
        require => Package['openjdk-7-jdk'],
    }

    class { '::archiva::gitfat':
        require => Class['::archiva']
    }

    # Bacula backups for /var/lib/archiva.
    if $::realm == 'production' {
        include role::backup::host
        backup::set { 'var-lib-archiva':
            require => Class['::archiva']
        }
    }

    ferm::service { 'rsync':
        proto => 'tcp',
        port  => '873',
    }

    # Set up a reverse proxy for the archiva service.
    class { 'role::archiva::proxy':
        archiva_port => $archiva_port,
    }
}


# == Class role::archiva::proxy
# Sets up a simple nginx reverse proxy.
# This must be included on the same node as the archiva server.
#
class role::archiva::proxy($archiva_port = 8080) {
    # Set up simple Nginx reverse proxy to $archiva_port.
    class { '::nginx': }

    # Should we use and force SSL for this nginx archiva proxy?
    $use_ssl = hiera('role::archiva::use_ssl', $::realm ? {
        'production' => true,
        default      => false,
    })

    $listen_port = $use_ssl ? {
        true    => 443,
        default => 80
    }


    $certificate_name = hiera('role::archiva::certificate_name', $::realm ? {
        'production' => 'archiva.wikimedia.org',
        default      => 'ssl-cert-snakeoil',
    })


    # Install the certificate if it is not the snakeoil cert
    if ($use_ssl and $certificate_name != 'ssl-cert-snakeoil') {
        install_certificate{ $certificate_name: }
    }
    $ssl_certificate = $certificate_name ? {
        'ssl-cert-snakeoil' => '/etc/ssl/certs/ssl-cert-snakeoil.pem',
        default             => "/etc/ssl/localcerts/${certificate_name}.crt",
    }
    $ssl_private_key = "/etc/ssl/private/${certificate_name}.key"


    # $archiva_server_properties and
    # $ssl_server_properties will be concatenated together to form
    # a single $server_properties array for the simple-proxy.erb
    # nginx site template.
    $archiva_server_properties = [
        # Need large body size to allow for .jar deployment.
        'client_max_body_size 256M',
        # Archiva sometimes takes a long time to respond.
        'proxy_connect_timeout 600s',
        'proxy_read_timeout 600s',
        'proxy_send_timeout 600s',
    ]

    $ssl_server_properties = $use_ssl ? {
        # Use puppet's stupidity to array concatenate the result of
        # ssl_ciphersuite and the locations of ssl certs.
        true    => [
            ssl_ciphersuite('nginx', 'compat'),
            [
                "ssl_certificate     ${ssl_certificate}",
                "ssl_certificate_key ${ssl_private_key}",
            ],
        ],
        default => [],
    }

    $listen = $use_ssl ? {
        true    => "$listen_port ssl",
        default => $listen_port,
    }
    $proxy_pass = "http://127.0.0.1:${archiva_port}/"
    # Use puppet's stupidity to do array contatenation.
    $server_properites = [$archiva_server_properties, $ssl_common_properties]

    nginx::site { 'archiva':
        content => template('nginx/sites/simple-proxy.erb'),
    }


    ferm::service { 'http':
        proto => 'tcp',
        port  => $listen_port,
    }
}