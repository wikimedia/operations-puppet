# Class: puppetmaster::scripts::frontend
#
# This class installs some puppetmaster server side scripts required by
# frontend puppetmaster.
#
class puppetmaster::scripts::frontend {
    # Helper script to clean stored data about a server we're reimaging.
    file { '/usr/local/bin/wmf-reimage':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0544',
        source  => 'puppet:///modules/puppetmaster/wmf-reimage',
    }

    # SSH into machines during installation and before the first puppet run
    file { '/usr/local/sbin/install-console':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0544',
        source  => 'puppet:///modules/puppetmaster/install-console',
    }
}
