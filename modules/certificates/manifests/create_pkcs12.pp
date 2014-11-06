define create_pkcs12(
    $certname   = $name,
    $cert_alias = '',
    $password   = '',
    $user       = 'root',
    $group      = 'ssl-cert',
    $location   = '/etc/ssl/private',
) {

    include passwords::certs

    if ( $cert_alias == '' ) {
        $certalias = $certname
    } else {
        $certalias = $cert_alias
    }

    if ( $password == '' ) {
        $defaultpassword = $passwords::certs::certs_default_pass
    } else {
        $defaultpassword = $password
    }
    # pkcs12 file, used by things like opendj, nss, and tomcat
    exec  { "${name}_create_pkcs12":
        creates => "${location}/${certname}.p12",
        command => "/usr/bin/openssl pkcs12 -export -name \"${certalias}\" -passout pass:${defaultpassword} -in /etc/ssl/localcerts/${certname}.crt -inkey /etc/ssl/private/${certname}.key -out ${location}/${certname}.p12",
        onlyif  => "/usr/bin/test -s /etc/ssl/private/${certname}.key",
        require => [Package['openssl'],
                    File["/etc/ssl/private/${certname}.key"],
                    File["/etc/ssl/localcerts/${certname}.crt"],
        ],
    }
    # Fix permissions on the p12 file, and make it available as
    # a puppet resource
    file { "${location}/${certname}.p12":
        ensure  => 'file',
        mode    => '0440',
        owner   => $user,
        group   => $group,
        require => Exec["${name}_create_pkcs12"],
    }
}

