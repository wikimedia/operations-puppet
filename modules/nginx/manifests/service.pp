# vim:sw=4:ts=4:et:

class nginx::service {

    include nginx::package

    service { ['nginx']:
        ensure  => running,
        enable  => true,
        require => Package['nginx'],
    }
}
