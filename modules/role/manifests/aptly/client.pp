# = Class: role::aptly::client
#
# Sets up a simple deb package that points to the project's aptly server
class role::aptly::client(
    $servername = "${::wmcs_project}-packages.${::wmcs_project}.${::site}.wmflabs",
    $components = 'main',
    $protocol = 'http',
) {
    class { '::aptly::client':
        servername => $servername,
        components => $components,
        protocol   => $protocol,
    }
}
