# @summary create pkcs12 file from a x509 public/private key pair
# @param public_key the location of the public key
# @param private_key the location of the private key
# @param outfile location to store the pkcs12 file
# @param certfile a certificate bundle to add to the exported file
define sslcert::x509_to_pkcs12 (
    Wmflib::Ensure              $ensure      = 'present',
    Stdlib::Unixpath            $public_key  = "/etc/ssl/localcerts/${title}.crt",
    Stdlib::Unixpath            $private_key = "/etc/ssl/private/${title}.key",
    Stdlib::Unixpath            $outfile     = "/etc/ssl/localcerts/${title}.p12",
    String                      $password    = '',
    String                      $owner       = 'root',
    String                      $group       = 'root',
    Optional[Stdlib::Unixpath]  $certfile    = undef,
) {
    ensure_packages(['openssl'])
    $_certfile = $certfile ? {
        undef   => '',
        default => "-certfile ${certfile}",
    }
    $command = @("COMMAND"/L)
        /usr/bin/openssl pkcs12 -export ${_certfile} \
        -in ${public_key} \
        -inkey ${private_key} \
        -out ${outfile} \
        -password 'pass:${password}'
        | COMMAND
    if $ensure == 'present' {
        exec {"sslcert generate ${title}.p12":
            command => $command,
            creates => $outfile,
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
