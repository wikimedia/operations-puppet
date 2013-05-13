# vim:sw=4:ts=4:et:

class protoproxy::package {

    package { ['nginx']:
        ensure => latest,
    }

    file { '/etc/nginx/sites-enabled/default':
        ensure => absent,
    }

}
