# ZIM dumps - https://en.wikipedia.org/wiki/ZIM_%28file_format%29
class dumps::zim {

    package { 'imagemagick':
        ensure => present,
    }

    package { [ 'nodejs', 'nodejs-legacy', 'nodejs-dev', 'npm' ]:
        ensure => present,
    }

    package { [ 'libsqlite3', 'libsqlite3-dev' ]:
        ensure => present,
    }

}
