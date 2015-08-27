# = Class: role::aptly
#
# Sets up a simple aptly repo server serving over http on port 80
class role::aptly {
    include ::aptly
}

# = Class: role::aptly::client
#
# Sets up a simple deb package that points to the project's aptly server
class role::aptly::client(
    $servername = "${labsproject}-packages.${labsproject}.${site}.wmflabs",
) {
    class { '::aptly::client':
        servername => $servername,
    }
}
