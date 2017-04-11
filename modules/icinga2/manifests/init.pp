
class icinga2() {
    $ichinga2_web_enable = hiera('icinga2_web2_enable', false)
    apt::repository { 'icinga2':
        uri        => 'http://packages.icinga.com/debian',
        dist       => 'icinga-jessie',
        components => 'main',
        source     => false,
        keyfile    => 'puppet:///modules/icinga2/icinga2.pgp',
    }

    if $ichinga2_web_enable {
      package { 'icingaweb2':
          ensure => present,
          require => [
              Apt::Repository['icinga2'],
          ],
      }
    }

    package { 'icinga2':
        ensure => present,
        require => [
            Apt::Repository['icinga2'],
        ],
    }
}
