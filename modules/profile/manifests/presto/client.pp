# == Class profile::presto::client
# Installs presto-cli and configures it to contact the Presto service at $discovery_uri
#
# == Parameters
#
# [*discovery_uri*]
#   URI to Presto discovery server.  This is likely the same as the coordinator port.
#
class profile::presto::client(
    String $cluster_name = hiera('profile::presto::cluster_name'),
    String $discovery_uri = hiera('profile::presto::discovery_uri'),
    Boolean $use_kerberos = hiera('profile::presto::use_kerberos', false),
) {

    file { '/usr/local/bin/presto':
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        content => template('profile/presto/presto_client_ssl_kerberos.erb'),
        require => Package['presto-cli'],
    }

    class { '::presto::client':
        discovery_uri => $discovery_uri,
    }
}
