define clush::target(
    $username = $title,
    $ensure = present,
) {

    user { $username:
        ensure     => $ensure,
        system     => true,
        home       => '/var/lib/clush',
        managehome => true,
    }

    ssh::userkey { $username:
        ensure  => $ensure,
        content => secret("clush/${username}.pub"),
        require => User[$username],
    }
}
