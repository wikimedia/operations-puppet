
class server() {

    apt::repository { 'icinga2':
        uri        => 'http://packages.icinga.com/debian',
        dist       => 'icinga-jessie',
        components => 'main',
        source     => false,
        keyfile    => 'puppet:///modules/icinga2/icinga2.pgp',
    }

    package { ['icinga2', 'icingaweb2']:
        ensure  => present,
        require => [
            Apt::Repository['icinga2'],
        ],
    }
}
