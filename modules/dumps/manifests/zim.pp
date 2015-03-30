# ZIM dumps - https://en.wikipedia.org/wiki/ZIM_%28file_format%29
class dumps::zim {

    package { 'imagemagick':
        ensure => present,
    }

}
