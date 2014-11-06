define create_chained_cert(
    $ca,
    $certname = $name,
    $user     = 'root',
    $group    = 'ssl-cert',
    $location = '/etc/ssl/localcerts',
) {
    # chained cert, used when needing to provide
    # an entire certificate chain to a client
    # NOTE: This is annoying because to work right regardless of whether
    # the root CA comes from the OS or us, we need to use the /etc/ssl/certs/
    # linkfarm so filenames need to use '*.pem'.

    exec { "${name}_create_chained_cert":
        creates => "${location}/${certname}.chained.crt",
        command => "/bin/cat /etc/ssl/localcerts/${certname}.crt ${ca} > ${location}/${certname}.chained.crt",
        cwd     => '/etc/ssl/certs',
        require => [Package['openssl'],
                    File["/etc/ssl/localcerts/${certname}.crt"],
        ],
    }
    # Fix permissions on the chained file, and make it available as
    file { "${location}/${certname}.chained.crt":
        ensure  => 'file',
        mode    => '0444',
        owner   => $user,
        group   => $group,
        require => Exec["${name}_create_chained_cert"],
    }

    # TODO: Remove once nothing references this anymore
    file { "/etc/ssl/certs/${certname}.chained.pem":
        ensure  => link,
        target  => "${location}/${certname}.chained.crt",
        require => File["${location}/${certname}.chained.crt"],
    }
}

