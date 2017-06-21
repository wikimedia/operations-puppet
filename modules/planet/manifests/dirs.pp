# sets up needed directories for a planet-venus intall
class planet::dirs {

    if os_version('debian == stretch') {

        file { [
            '/var/www/planet',
            '/var/log/planet',
            '/etc/rawdog/',
            '/etc/rawdog/theme',
            '/etc/rawdog/theme/wikimedia',
            ]:
            ensure => 'directory',
            owner  => 'planet',
            group  => 'planet',
            mode   => '0755',
        }

    } else {

        file { [
            '/var/www/planet',
            '/var/log/planet',
            '/usr/share/planet-venus/wikimedia',
            '/usr/share/planet-venus/theme/wikimedia',
            '/usr/share/planet-venus/theme/common',
            '/var/cache/planet',
            ]:
            ensure => 'directory',
            owner  => 'planet',
            group  => 'planet',
            mode   => '0755',
        }
    }
}
