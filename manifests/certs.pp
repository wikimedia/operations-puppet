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
    $ca,
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
    if ( $ca ) {
        $cas = $ca
    } else {
        # PEM files should be listed in order:
        # intermediate -> intermediate -> ... -> root
        # If this is out of order either servers will fail to start,
        # or will not properly have SSL enabled.
        $cas = $name ? {
            # NOTE: Those use .pem filenames
            'unified.wikimedia.org'        => 'DigiCertHighAssuranceCA-3.pem',
            'star.wikimedia.org'           => 'RapidSSL_CA.pem RapidSSL_CA_2.pem GeoTrust_Global_CA.pem',
            'star.wikipedia.org'           => 'DigiCertHighAssuranceCA-3.pem DigiCert_High_Assurance_EV_Root_CA.pem',
            'star.wiktionary.org'          => 'RapidSSL_CA.pem GeoTrust_Global_CA.pem',
            'star.wikiquote.org'           => 'RapidSSL_CA.pem GeoTrust_Global_CA.pem',
            'star.wikibooks.org'           => 'RapidSSL_CA.pem GeoTrust_Global_CA.pem',
            'star.wikisource.org'          => 'RapidSSL_CA.pem GeoTrust_Global_CA.pem',
            'star.wikinews.org'            => 'RapidSSL_CA.pem GeoTrust_Global_CA.pem',
            'star.wikiversity.org'         => 'RapidSSL_CA.pem GeoTrust_Global_CA.pem',
            'star.mediawiki.org'           => 'RapidSSL_CA.pem GeoTrust_Global_CA.pem',
            'star.wikimediafoundation.org' => 'RapidSSL_CA.pem GeoTrust_Global_CA.pem',
            'star.wmflabs.org'             => 'RapidSSL_CA.pem GeoTrust_Global_CA.pem',
            'star.wmflabs'                 => 'wmf-labs.pem',
            'star.planet.wikimedia.org'    => 'DigiCertHighAssuranceCA-3.pem DigiCert_High_Assurance_EV_Root_CA.pem',
            'star.wmfusercontent.org'      => 'GlobalSign_CA.pem',
            default => 'wmf-ca.pem',
        }
    }
    create_chained_cert{ $name:
        ca => $cas,
    }
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
        group  => 'ca-certs',
        mode   => '0755',
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
