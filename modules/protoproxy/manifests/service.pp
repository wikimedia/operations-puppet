# vim:sw=4:ts=4:et:

class protoproxy::service {

    include protoproxy::package

    service { ['nginx']:
        ensure  => running,
        enable  => true,
        require => Package['nginx'],
    }
}
