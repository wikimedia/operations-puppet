define create_combined_cert(
    $certname = $name,
    $user     = 'root',
    $group    = 'ssl-cert',
    $location = '/etc/ssl/private',
) {
    # combined cert, used by things like lighttp and nginx
    exec { "${name}_create_combined_cert":
        creates => "${location}/${certname}.crt",
        command => "/bin/cat /etc/ssl/localcerts/${certname}.crt /etc/ssl/private/${certname}.key > ${location}/${certname}.crt",
        require => [Package['openssl'],
                    File["/etc/ssl/private/${certname}.key"],
                    File["/etc/ssl/localcerts/${certname}.crt"],
        ];
    }
    # Fix permissions on the combined file, and make it available as
    # a puppet resource
    file { "${location}/${certname}.crt":
        ensure  => 'file',
        mode    => '0440',
        owner   => $user,
        group   => $group,
        require => Exec["${name}_create_combined_cert"],
    }

    # TODO: Remove once nothing references this anymore
    file { "${location}/${certname}.pem":
        ensure  => link,
        target  => "${location}/${certname}.crt",
        require => File["${location}/${certname}.crt"],
    }
}

