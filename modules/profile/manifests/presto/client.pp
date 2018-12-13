# == Class profile::presto::client
# Installs presto-cli and configures it to contact the Presto service at $discovery_uri
#
# == Parameters
#
# [*discovery_uri*]
#   URI to Presto discovery server.  This is likely the same as the coordinator port.
#
class profile::presto::client(
    $discovery_uri = hiera('profile::presto::discovery_uri'),
) {
    class { '::presto::client':
        discovery_uri => $discovery_uri,
    }
}
