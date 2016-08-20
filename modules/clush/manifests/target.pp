# = Class: clush::target
#
# Sets up a host to allow ssh from a clush master.
# Only sets up username & ssh key, expects the key
# to be available using `secret` from clush/${username}.pub
#
# == Parameters:
# [*ensure*]
#   Should this user / key be present or absent
#
# [*username*]
#   Same as $title, name of user to create
#
define clush::target(
    $ensure = present,
    $username = $title,
) {

    user { $username:
        ensure     => $ensure,
        system     => true,
        home       => '/var/lib/clush',
        managehome => true,
        shell      => '/bin/bash',
    }

    ssh::userkey { $username:
        ensure  => $ensure,
        content => secret("clush/${username}.pub"),
        require => User[$username],
    }
}
