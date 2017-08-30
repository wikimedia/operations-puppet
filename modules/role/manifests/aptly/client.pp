# = Class: role::aptly::client
#
# Sets up a simple deb package that points to the project's aptly server
class role::aptly::client(
    $servername = "${::labsproject}-packages.${::labsproject}.${::site}.wmflabs",
    $components = 'main',
    $protocol = 'http',
) {
    class { '::aptly::client':
        servername => $servername,
        components => $components,
        protocol   => $protocol,
    }
}
