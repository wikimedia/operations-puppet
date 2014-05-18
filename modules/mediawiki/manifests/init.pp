class mediawiki {
    include ::mediawiki::users
    include ::mediawiki::sync
    include ::mediawiki::cgroup
    include ::mediawiki::packages
    include ::mediawiki::config::base
    include ::mediawiki::service

    class { '::twemproxy':
        default_file => 'puppet:///modules/mediawiki/twemproxy.default',
    }
}
