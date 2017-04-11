
class icinga2() {
    apt::repository { 'icinga2':
        uri        => 'http://packages.icinga.com/debian',
        dist       => 'icinga-jessie',
        components => 'main',
        source     => false,
        keyfile    => 'puppet:///modules/icinga2/icinga2.pgp',
    }
}
