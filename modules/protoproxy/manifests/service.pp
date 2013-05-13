# vim:sw=4:ts=4:et:

class protoproxy::service {
    service { ['nginx']:
        ensure => running,
        enable => true,
    }
}
