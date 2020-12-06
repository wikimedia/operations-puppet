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
    String $cluster_name = lookup('profile::presto::cluster_name'),
    String $discovery_uri = lookup('profile::presto::discovery_uri'),
    Boolean $use_kerberos = lookup('profile::presto::use_kerberos', { 'default_value' => false }),
    Optional[Hash[String, Hash[String, String]]] $presto_clusters_secrets = lookup('presto_clusters_secrets', { 'default_value' => {} }),
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
