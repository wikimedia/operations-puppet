# == Class: base::phaste
#
# Provisions 'phaste', a simple command-line tool for pastebinning text
# onto Phabricator.
#
class base::phaste( $ensure = present ) {
    include ::passwords::phabricator

    $conf = {
        user => 'ProdPasteBot',
        cert => $passwords::phabricator::pastebot_cert,
        phab => 'https://phabricator.wikimedia.org',
    }

    file { '/etc/phaste.conf':
        ensure  => $ensure,
        content => ordered_json($conf),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    file { '/usr/local/bin/phaste':
        ensure  => $ensure,
        source  => 'puppet:///modules/base/phaste.py',
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        require => File['/etc/phaste.conf'],
    }
}
