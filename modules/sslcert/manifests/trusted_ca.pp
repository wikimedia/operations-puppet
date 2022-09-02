# SPDX-License-Identifier: Apache-2.0
# @summary Deploy a .pem file containing the WMF's internal Root CA crts.
#          Create a .p12 truststore if needed.
# @param trusted_certs a list of certificate files to add to the tristed cert store
# @param p12_truststore_path location on the fs where to create the .p12 truststore
# @param jks_truststore_path location on the fs where to create the .jks truststore
# @param owner user set as owner of the files to be created
# @param group group set as group-owner of the files to be created
class sslcert::trusted_ca (
    Wmflib::Ensure                   $ensure              = 'present',
    String                           $truststore_password = 'changeit',
    String                           $owner               = 'root',
    String                           $group               = 'root',
    Boolean                          $include_bundle_jks  = false,
    Optional[Sslcert::Trusted_certs] $trusted_certs       = undef,
) {

    contain sslcert

    if $trusted_certs {
        $trusted_ca_path = $trusted_certs['bundle']
        $jks_truststore_path = $include_bundle_jks ? {
            true    => "${sslcert::localcerts}/wmf-java-cacerts",
            default => undef,
        }
        if 'package' in $trusted_certs {
            ensure_packages($trusted_certs['package'])
            $res_subscribe = Package[$trusted_certs['package']]
        } else {
            concat { $trusted_ca_path:
                ensure => present,
                owner  => $owner,
                group  => $group,
                mode   => '0644',
                notify => Exec['generate trusted_ca'],
            }

            $trusted_certs['certs'].each |Integer $index, Stdlib::Unixpath $cert| {
                file { "${sslcert::localcerts}/${cert.basename}":
                    ensure => absent,
                }

                concat::fragment { "ssl-ca-${cert}":
                    source => $cert,
                    target => $trusted_ca_path,
                    order  => $index,
                    notify => Exec['generate trusted_ca'],
                }
            }

            # no-op resource used for propagating notifies
            exec { 'generate trusted_ca':
                command     => '/bin/true',
                refreshonly => true,
            }
            $res_subscribe = Exec['generate trusted_ca']
        }
        $trusted_certs['certs'].each |$cert| {
            if $include_bundle_jks {
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
                    subscribe     => $res_subscribe,
                }
                Class['java'] -> Java::Cacert[$cert_basename]
            }
        }
    } else {
        $trusted_ca_path = $facts['puppet_config']['localcacert']
        $jks_truststore_path = $include_bundle_jks ? {
            true    => '/etc/ssl/certs/java/cacerts',
            default => undef,
        }
    }
}
