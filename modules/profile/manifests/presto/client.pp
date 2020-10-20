# == Class profile::presto::client
# Installs presto-cli and configures it to contact the Presto service at $discovery_uri
#
# == Parameters
#
# [*discovery_uri*]
#   URI to Presto discovery server.  This is likely the same as the coordinator port.
#
#  [*presto_clusters_secrets*]
#    Hash of available/configured Presto clusters and their secret properties,
#    like passwords, etc..
#    The following values will be checked in the hash table only if TLS/Kerberos
#    configs are enabled (see in the code for the exact values).
#      - 'ssl_keystore_password'
#    Default: {}
#
class profile::presto::client(
    String $cluster_name = hiera('profile::presto::cluster_name'),
    String $discovery_uri = hiera('profile::presto::discovery_uri'),
    Boolean $use_kerberos = hiera('profile::presto::use_kerberos', false),
    Optional[Hash[String, Hash[String, String]]] $presto_clusters_secrets = hiera('presto_clusters_secrets', {}),
) {

    if $presto_clusters_secrets[$cluster_name] {
        # Presto seems not picking up the JVM default truststore's cert
        $ssl_truststore_path = '/etc/ssl/certs/java/cacerts'
        $ssl_truststore_password = 'changeit'

        file { '/usr/local/bin/presto':
            owner   => 'root',
            group   => 'root',
            mode    => '0555',
            content => template('profile/presto/presto_client_ssl_kerberos.erb'),
            require => Package['presto-cli'],
        }
    }

    class { '::presto::client':
        discovery_uri => $discovery_uri,
    }
}
