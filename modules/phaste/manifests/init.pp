# == Class: phaste
#
# Description
#
# === Parameters
#
# [*user*]
#   Username the bot should use to authenticate.
#
# [*cert*]
#   Conduit certificate for the phaste user.
#
# [*phab*]
#   URL of Phabricator instance.
#
# === Examples
#
#  class { 'phaste':
#    user => 'ProdPasteBot',
#    cert => 'dmalem5s...',
#    phab => 'https://phabricator.wikimedia.org',
#  }
#
class phaste(
    $user,
    $cert,
    $phab,
    $ensure = present,
) {
    validate_ensure($ensure)
    validate_slength($cert, 255)

    file { '/etc/phaste.conf':
        ensure  => $ensure,
        content => ordered_json({user => $user, cert => $cert, phab => $phab}),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    file { '/usr/local/bin/phaste':
        ensure  => $ensure,
        source  => 'puppet:///modules/phaste/phaste',
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        require => File['/etc/phaste.conf'],
    }
}
