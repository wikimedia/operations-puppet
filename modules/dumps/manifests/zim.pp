# ZIM dumps - https://en.wikipedia.org/wiki/ZIM_%28file_format%29
class dumps::zim {

    package { 'imagemagick':
        ensure => present,
    }

    package { [ 'nodejs', 'nodejs-legacy', 'libsqlite3-0' ]:
        ensure => present,
    }

    # nginx serving these via http only, with another host
    # proxying all requests. can't use the standard dumps nginx
    # manifest. all of the code below is for this setup, which
    # is temporary.

    file { '/srv/www':
        ensure => directory,
        mode   => '0755',
        owner  => 'root',
        group  => 'www-data',
    }

    file { '/srv/www/htmldumps':
        ensure => directory,
        mode   => '0755',
        owner  => 'root',
        group  => 'www-data',
    }

    # don't know if we want bw limits etc so let's slap 'extras'
    # on there
    class { '::nginx':
        variant => 'extras',
    }

    nginx::site { 'zim':
        source => 'puppet:///modules/dumps/nginx.zim.conf',
        notify => Service['nginx'],
    }
}
