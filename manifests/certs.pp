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

define create_chained_cert(
    $certname = $name,
    $user     = 'root',
    $group    = 'ssl-cert',
    $location = '/etc/ssl/localcerts',
) {
    # chained cert, used when needing to provide
    # an entire certificate chain to a client
    # XXX: this actually ignores the specificed $ca now

    exec { "${name}_create_chained_cert":
        creates => "${location}/${certname}.chained.crt",
        command => "/usr/local/bin/construct-cert-chain ${certname}.crt > ${location}/${certname}.chained.crt",
        cwd     => '/etc/ssl/localcerts',
        require => [Package['openssl'],
                    File['/usr/local/bin/construct-cert-chain'],
                    File["/etc/ssl/localcerts/${certname}.crt"],
        ],
    }
    # Fix permissions on the chained file, and make it available as
    file { "${location}/${certname}.chained.crt":
        ensure  => 'file',
        mode    => '0444',
        owner   => $user,
        group   => $group,
        require => [
                    File["/etc/ssl/localcerts/${certname}.crt"],
                    Exec["${name}_create_chained_cert"],
        ],
    }

    # TODO: Remove once nothing references this anymore
    file { "/etc/ssl/certs/${certname}.chained.pem":
        ensure  => link,
        target  => "${location}/${certname}.chained.crt",
        require => File["${location}/${certname}.chained.crt"],
    }
}

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

define install_certificate(
    $group     = 'ssl-cert',
    $ca        = '',
    $privatekey=true,
) {

    require certificates::base,
        certificates::rapidssl_ca,
        certificates::rapidssl_ca_2,
        certificates::digicert_ca,
        certificates::wmf_ca,
        certificates::wmf_ca_2014_2017

    # Public key
    file { "/etc/ssl/localcerts/${name}.crt":
        owner   => 'root',
        group   => $group,
        mode    => '0444',
        source  => "puppet:///files/ssl/${name}.crt",
        require => File['/etc/ssl/localcerts'],
    }

    # TODO: Remove once nothing references this anymore
    file { "/etc/ssl/certs/${name}.pem":
        ensure  => link,
        target  => "/etc/ssl/localcerts/${name}.crt",
        require => File["/etc/ssl/localcerts/${name}.crt"],
    }

    if ( $privatekey == true ) {
        # Private key
        file { "/etc/ssl/private/${name}.key":
            owner  => 'root',
            group  => $group,
            mode   => '0440',
            source => "puppet:///private/ssl/${name}.key",
        }
    } else {
        # empty Private key
        file { "/etc/ssl/private/${name}.key":
            ensure => 'present',
        }
    }

    create_pkcs12{ $name: }
    create_combined_cert{ $name: }
    create_chained_cert{ $name: }
}

define install_additional_key(
    $key_loc = '',
    $owner   = 'root',
    $group   = 'ssl-cert',
    $mode    = '0440',
) {

    if ( $key_loc ) {
        file { "${key_loc}/${name}.key":
            owner   => $owner,
            group   => $group,
            mode    => $mode,
            source  => "puppet:///private/ssl/${name}.key",
            require => Package['openssl'],
        }
    }
}

class certificates::base {

    include apparmor

    package { [ 'openssl', 'ssl-cert' ]:
        ensure => 'latest',
    }

    exec { 'update-ca-certificates':
        command => '/usr/sbin/update-ca-certificates',
        refreshonly => true,
    }

    package { 'ca-certificates':
        ensure => 'latest',
        notify => Exec['update-ca-certificates'],
    }

    # Server certificates now uniformly go in there
    file { '/etc/ssl/localcerts':
        ensure => directory,
        owner  => 'root',
        group  => 'ssl-cert',
        mode   => '0755',
    }

    ## NOTE: The ssl_certs abstraction for apparmor is known to exist
    ## and be mutually compatible up to Trusty; new versions will need
    ## validation before they are cleared.

    if versioncmp($::lsbdistrelease, '14.04') > 0 {
        fail("The apparmor profile for certificates::base is only known to work up to Trusty")
    }
    file { '/etc/apparmor.d/abstractions/ssl_certs':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///files/ssl/ssl_certs',
        notify => Service['apparmor'],
    }

    file { '/usr/local/bin/construct-cert-chain':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => 'puppet:///files/ssl/construct-cert-chain',
        require => Package['openssl'],
    }
}

class certificates::star_wmflabs_org {

    install_certificate{ 'star.wmflabs.org': }

}

class certificates::star_wmflabs {

    install_certificate{ 'star.wmflabs': }

}

# TODO: define this
# old lost CA, need to remove from all over
class certificates::wmf_ca {

    include certificates::base

    file { '/usr/local/share/ca-certificates/wmf-ca.crt':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///files/ssl/wmf-ca.crt',
        require => Package['openssl'],
        notify  => Exec['update-ca-certificates'],
    }

}

class certificates::wmf_ca_2014_2017 {

    include certificates::base
    $ca_name = 'wmf_ca_2014_2017'

    file { "/usr/local/share/ca-certificates/${ca_name}.crt":
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => "puppet:///files/ssl/${ca_name}.crt",
        require => Package['openssl'],
        notify  => Exec['update-ca-certificates'],
    }

}

class certificates::wmf_labs_ca {

    include certificates::base

    file { '/usr/local/share/ca-certificates/wmf-labs.crt':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///files/ssl/wmf-labs.crt',
        require => Package['openssl'],
        notify  => Exec['update-ca-certificates'],
    }

}

class certificates::rapidssl_ca {

    include certificates::base

    file { '/usr/local/share/ca-certificates/RapidSSL_CA.crt':
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            source  => 'puppet:///files/ssl/RapidSSL_CA.crt',
            require => Package['openssl'],
            notify  => Exec['update-ca-certificates'],
    }
}

class certificates::rapidssl_ca_2 {

    include certificates::base

    file { '/usr/local/share/ca-certificates/RapidSSL_CA_2.crt':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///files/ssl/RapidSSL_CA_2.crt',
        require => Package['openssl'],
        notify  => Exec['update-ca-certificates'],
    }
}

class certificates::digicert_ca {

    include certificates::base

    file { '/usr/local/share/ca-certificates/DigiCertHighAssuranceCA-3.crt':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///files/ssl/DigiCertHighAssuranceCA-3.crt',
        require => Package['openssl'],
        notify  => Exec['update-ca-certificates'],
    }
}

class certificates::globalsign_ca {

    include certificates::base

    file { '/usr/local/share/ca-certificates/GlobalSign_CA.crt':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///files/ssl/GlobalSign_CA.crt',
        require => Package['openssl'],
        notify  => Exec['update-ca-certificates'],
    }
}
