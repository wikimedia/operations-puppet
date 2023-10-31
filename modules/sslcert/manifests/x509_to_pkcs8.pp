# SPDX-License-Identifier: Apache-2.0
# @summary create pkcs8 file from a x509 public/private key pair
# @param ensure ensureable parameter
# @param public_key the location of the public key
# @param private_key the location of the private key
# @param outfile location to store the pkcs12 file
# @param passphrase private key passphrase
# @param owner File user permissions
# @param group File group permissions
# @param certfile a certificate bundle to add to the exported file
define sslcert::x509_to_pkcs8 (
    Wmflib::Ensure              $ensure      = 'present',
    Stdlib::Unixpath            $public_key  = "/etc/ssl/localcerts/${title}.crt",
    Stdlib::Unixpath            $private_key = "/etc/ssl/private/${title}.key",
    Stdlib::Unixpath            $outfile     = "/etc/ssl/localcerts/${title}.p12",
    Optional[String[1]]         $passphrase  = undef,
    String                      $owner       = 'root',
    String                      $group       = 'root',
) {
    ensure_packages(['openssl'])
    $_passphrase = $passphrase ? {
        undef   => '-nocrypt',
        default => "-passin ${passphrase}",
    }

    $convert_cmd = "/usr/bin/openssl pkcs8 -topk8 -in ${private_key} ${_passphrase} -out ${outfile}"
    $check_certificates_match = @("CHECK_CERTIFICATES_MATCH_COMMAND"/L)
        /usr/bin/test \
        "$(/usr/bin/openssl x509 -in ${public_key} -noout -pubkey 2>&1)" == \
        "$(/usr/bin/openssl pkey -pubout -in ${outfile} 2>&1)"
        | CHECK_CERTIFICATES_MATCH_COMMAND

    if $ensure == 'present' {
        exec { "Convert ${title} private key to PCKS#8 format":
            command => $convert_cmd,
            unless  => $check_certificates_match,
            require => Package['openssl'],
            before  => File[$outfile]
        }
    }

    file {$outfile:
        ensure => $ensure,
        owner  => $owner,
        group  => $group,
        mode   => '0440',
    }
}
