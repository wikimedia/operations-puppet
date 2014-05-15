class mediawiki {
    include ::mediawiki::users::mwdeploy
    include ::mediawiki::users::l10nupdate
    include ::mediawiki::users::sudo
    include ::mediawiki::sync
    include ::mediawiki::cgroup
    include ::mediawiki::packages

    class { '::twemproxy':
        default_file => 'puppet:///modules/mediawiki/twemproxy.default',
    }
}
