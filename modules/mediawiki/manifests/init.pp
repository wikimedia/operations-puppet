class mediawiki {
    include ::mediawiki::users
    include ::mediawiki::sync
    include ::mediawiki::cgroup
    include ::mediawiki::packages

    class { '::twemproxy':
        default_file => 'puppet:///modules/mediawiki/twemproxy.default',
    }
}
