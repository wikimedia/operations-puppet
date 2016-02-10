# == Class: mediawiki::mwrepl
#
# 'mwrepl' is a command line REPL, read-eval-print-loop, utility. This
# module ensures that mwrepl is installed, and that the per-user 
# configuration is in place.

class mediawiki::mwrepl {
    include ::mediawiki::users

    file { '/var/lib/hphpd':
        ensure => directory,
        owner  => $::mediawiki::users::web,
        group  => $::mediawiki::users::web,
        mode   => '0775',
    }

    file { '/var/lib/hphpd/hphpd.ini':
        source => 'puppet:///modules/mediawiki/hphpd.ini',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }

    file { '/usr/local/bin/mwrepl':
        source => 'puppet:///modules/mediawiki/mwrepl',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }
}
