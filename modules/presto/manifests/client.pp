# Class: presto::client
#
# Simple class that installs presto-cli package and sets up a config.properties
# file with the only a discovery.uri to connect to a presto cluster.
# NOTE: Do not include this class on a node that has presto::server.
#
# == Parameters ==
# [*discovery_uri*]
#   Presto cluster HTTP discovery URI for presto-cli to connect to.
#
class presto::client(String $discovery_uri = 'http://localhost:8080') {
    if defined(Class['::presto::server']) {
        fail('Class presto::client and presto::server should not be included on the same node; presto::server will include the presto-cli package itself.')
    }

    require_package('presto-cli')

    presto::properties { 'config':
        properties => {
            'discovery.uri' => $discovery_uri,
        }
    }
}
