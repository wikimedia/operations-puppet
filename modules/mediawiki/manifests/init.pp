class mediawiki {
    include ::mediawiki::users
    include ::mediawiki::sync
    include ::mediawiki::cgroup
    include ::mediawiki::packages
    include ::mediawiki::config::base
    include ::mediawiki::mwlogdir

    file { '/etc/cluster':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => $::site,
    }

    class { '::twemproxy':
        default_file => 'puppet:///modules/mediawiki/twemproxy.default',
    }
}
