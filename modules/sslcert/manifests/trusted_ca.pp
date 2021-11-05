# @summary Deploy a .pem file containing the WMF's internal Root CA crts.
#          Create a .p12 truststore if needed.
# @param trusted_root_ca_source the puppet source location of the .pem file
# @param trusted_ca_path the location on the fs where to deploy the .pem file
# @param p12_truststore_path location on the fs where to create the .p12 truststore
# @param jks_truststore_path location on the fs where to create the .jks truststore
# @param owner user set as owner of the files to be created
# @param group group set as group-owner of the files to be created
define sslcert::trusted_ca (
    Wmflib::Ensure             $ensure                 = 'present',
    String                     $trusted_root_ca_source = 'puppet:///modules/sslcert/trusted_root_ca.pem',
    Stdlib::Unixpath           $trusted_ca_path        = '/etc/ssl/localcerts/trusted_root_ca.pem',
    String                     $truststore_password    = '',
    String                     $owner                  = 'root',
    String                     $group                  = 'root',
    Optional[Stdlib::Unixpath] $p12_truststore_path    = undef,
    Optional[Stdlib::Unixpath] $jks_truststore_path    = undef,
) {
    # Deploy the WMF internal/trusted CAs as bundle .pem file.
    file { $trusted_ca_path:
        ensure => $ensure,
        owner  => $owner,
        group  => $group,
        mode   => '0444',
        source => $trusted_root_ca_source,
    }

    # If a PKCS12 truststore is needed, create a .p12 file from the above .pem file.
    if $p12_truststore_path {
        ensure_packages(['openssl'])
        file { $p12_truststore_path:
            ensure => $ensure,
            owner  => $owner,
            group  => $group,
            mode   => '0444',
        }
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
                require => Package['openssl'],
                before  => File[$p12_truststore_path],
            }
        }
    }

    # Same thing if a jks truststore is needed. In this case, since the keytool
    # command is needed, Java dependencies will be deployed as well.
    if $jks_truststore_path {
        file { $jks_truststore_path:
            ensure => $ensure,
            owner  => $owner,
            group  => $group,
            mode   => '0444',
        }
        java::cacert { $title:
            ensure        => $ensure,
            path          => $trusted_ca_path,
            storepass     => $truststore_password,
            keystore_path => $jks_truststore_path,
        }
    }
}
