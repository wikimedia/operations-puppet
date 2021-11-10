# @summary Deploy a .pem file containing the WMF's internal Root CA crts.
#          Create a .p12 truststore if needed.
# @param trusted_certs a list of certificate files to add to the tristed cert store
# @param p12_truststore_path location on the fs where to create the .p12 truststore
# @param jks_truststore_path location on the fs where to create the .jks truststore
# @param owner user set as owner of the files to be created
# @param group group set as group-owner of the files to be created
class sslcert::trusted_ca (
    Wmflib::Ensure             $ensure                 = 'present',
    String                     $truststore_password    = 'changeit',
    String                     $owner                  = 'root',
    String                     $group                  = 'root',
    Array[Stdlib::Unixpath]    $trusted_certs          = [],
    Optional[Stdlib::Unixpath] $p12_truststore_path    = undef,
    Optional[Stdlib::Unixpath] $jks_truststore_path    = undef,
) {

    contain sslcert

    unless $trusted_certs.empty {
        $trusted_ca_path = "${sslcert::localcerts}/wmf_trusted_root_CAs.pem"

        $trusted_certs.each |$cert| {
            # The following file resources is only used so we no when the source
            # file changes and thus know when to notify the exec and rebuild the bundle
            file { "${sslcert::localcerts}/${cert.basename}":
                ensure => file,
                owner  => $owner,
                group  => $group,
                mode   => '0444',
                source => $cert,
                notify => Exec['generate trusted_ca'],
            }
            if $jks_truststore_path {
                $cert_basename = '.pem' in $cert.basename ? {
                    true  => $cert.basename('.pem'),
                    false => $cert.basename('.crt'),
                }
                java::cacert { $cert_basename:
                    ensure        => $ensure,
                    owner         => $owner,
                    path          => $cert,
                    storepass     => $truststore_password,
                    keystore_path => $jks_truststore_path,
                }
            }
        }
        exec { 'generate trusted_ca':
            command     => "/bin/cat ${trusted_certs.join(' ')} > ${trusted_ca_path}",
            refreshonly => true,
            user        => $owner,
            group       => $group,
        }

        # If a PKCS12 truststore is needed, create a .p12 file from the above .pem file.
        if $p12_truststore_path {
            $create_pkcs12_command = @("CREATE_PKCS12_COMMAND"/L)
                /usr/bin/openssl pkcs12 -export \
                -nokeys -in ${trusted_ca_path} -out ${p12_truststore_path} \
                -password 'pass:${truststore_password}'
                |- CREATE_PKCS12_COMMAND

            $check_certificates_match = @("CHECK_CERTIFICATES_MATCH_COMMAND"/L)
                /usr/bin/test \
                    "$(/usr/bin/openssl x509 -in ${trusted_ca_path})" == \
                    "$(/usr/bin/openssl pkcs12 \
                    -password 'pass:${truststore_password}' \
                    -in ${trusted_ca_path} -nokeys | openssl x509)"
                |- CHECK_CERTIFICATES_MATCH_COMMAND

            if $ensure == 'present' {
                exec {"sslcert generate ${p12_truststore_path}":
                    command => $create_pkcs12_command,
                    unless  => $check_certificates_match,
                    user    => $owner,
                    group   => $group,
                    require => Exec['generate trusted_ca'],
                }
            }
        }
    }
}
