# = Class: role::aptly::client
#
# Sets up a simple deb package that points to the project's aptly server
# TODO: convert this to a profile
class role::aptly::client(
    Stdlib::Fqdn          $servername,
    Array[String[1]]      $components   = ['main'],
    Enum['http', 'https'] $protocol     = 'http',
    Boolean               $auto_upgrade = true,
) {
    class { 'aptly::client':
        servername   => $servername,
        components   => $components,
        protocol     => $protocol,
        auto_upgrade => $auto_upgrade,
    }
}
