# = Class: role::aptly
#
# Sets up a simple aptly repo server serving over http on port 80
#
class role::aptly::server {
    include ::aptly

    aptly::repo { "stretch-${::labsproject}":
        publish => true,
        user    => $::aptly::owner,
    }
}
