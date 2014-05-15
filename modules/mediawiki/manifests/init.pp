class mediawiki {
    include ::mediawiki::users::mwdeploy
    include ::mediawiki::users::l10nupdate
    include ::mediawiki::users::sudo
    include ::mediawiki::sync
    include ::mediawiki::cgroup
    include ::mediawiki::packages

    # The name, gid, home, and shell of the apache user are set to conform
    # with the postinst script of the wikimedia-task-appserver package, which
    # provisioned it historically. These values can and should be modernized.

    group { 'apache':
        ensure => present,
        gid    => 48,
        system => true,
    }

    user { 'apache':
        ensure     => present,
        gid        => 48,
        shell      => '/sbin/nologin',
        home       => '/var/www',
        system     => true,
        managehome => false,
    }

    class { '::twemproxy':
        default_file => 'puppet:///modules/mediawiki/twemproxy.default',
    }
}
