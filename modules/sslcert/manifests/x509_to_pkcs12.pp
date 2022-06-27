# @summary create pkcs12 file from a x509 public/private key pair
# @param ensure ensureable parameter
# @param public_key the location of the public key
# @param private_key the location of the private key
# @param outfile location to store the pkcs12 file
# @param password password for p12 file
# @param owner File user permissions
# @param group File group permissions
# @param certfile a certificate bundle to add to the exported file
define sslcert::x509_to_pkcs12 (
    Wmflib::Ensure              $ensure      = 'present',
    Stdlib::Unixpath            $public_key  = "/etc/ssl/localcerts/${title}.crt",
    Stdlib::Unixpath            $private_key = "/etc/ssl/private/${title}.key",
    Stdlib::Unixpath            $outfile     = "/etc/ssl/localcerts/${title}.p12",
    Optional[String[1]]         $password    = undef,
    String                      $owner       = 'root',
    String                      $group       = 'root',
    Optional[Stdlib::Unixpath]  $certfile    = undef,
) {
    ensure_packages(['openssl'])
    $_certfile = $certfile ? {
        undef   => '',
        default => "-certfile ${certfile}",
    }
    $_password = $password ? {
        undef   => '',
        default => $password,
    }
    $create_pkcs12_command = @("CREATE_PKCS12_COMMAND"/L)
        /usr/bin/openssl pkcs12 -export ${_certfile} \
        -in ${public_key} \
        -inkey ${private_key} \
        -out ${outfile} \
        -password 'pass:${_password}'
        |- CREATE_PKCS12_COMMAND

    $check_certificates_match = @("CHECK_CERTIFICATES_MATCH_COMMAND"/L)
        /usr/bin/test \
            "$(/usr/bin/openssl x509 -in ${public_key})" == \
            "$(/usr/bin/openssl pkcs12 -password 'pass:${password}' -in ${outfile} -clcerts -nokeys | openssl x509)"
        |- CHECK_CERTIFICATES_MATCH_COMMAND

    if $ensure == 'present' {
        exec {"sslcert generate ${title}.p12":
            command => $create_pkcs12_command,
            unless  => $check_certificates_match,
            require => Package['openssl'],
            before  => File[$outfile],
        }
    }
    file {$outfile:
        ensure => $ensure,
        owner  => $owner,
        group  => $group,
        mode   => '0440',
    }
}
