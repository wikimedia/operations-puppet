# == Class statistics::compute
# Class containing common stuff for a statisitics compute node.
#
class statistics::compute {
    Class['::statistics']       -> Class['::statistics::compute']
    Class['::statistics::user'] -> Class['::statistics::compute']

    include ::statistics::dataset_mount
    include ::statistics::packages

    require_package('udp-filter')

    $working_path = $::statistics::working_path
    # Create $working_path/published-datasets.  Anything in this directory
    # will be available at analytics.wikimedia.org/datasets.
    # See: class statistics::sites::analytics.
    file { "${working_path}/published-datasets":
        ensure => 'directory',
        owner  => 'root',
        group  => 'wikidev',
        mode   => '0775',
    }
    file { "${working_path}/published-datasets/README":
        ensure => 'present',
        source => 'puppet:///modules/statistics/published-datasets-readme.txt',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }

    # Rync push published-datasets from this host to thorium,
    # the analytics.wikimedia.org web host.  These will end up at
    # /srv/published-datasets-rsynced/$hostname, and then the hardsync script
    # will sync them into /srv/analytics.wikimedia.org/datasets.
    # See: statistics::sites::analytics.
    cron { 'rsync-published-datasets':
        command => "/usr/bin/rsync -rt --delete ${working_path}/published-datasets/ thorium.eqiad.wmnet::srv/published-datasets-rsynced/${::hostname}/",
        require => File["${working_path}/public-datasets"],
        user    => 'root',
        minute  => '*/30',
    }

    # clones mediawiki core at $working_path/mediawiki/core
    # and ensures that it is at the latest revision.
    # T80444
    $statistics_mediawiki_directory = "${::statistics::working_path}/mediawiki/core"

    git::clone { 'statistics_mediawiki':
        ensure    => 'latest',
        directory => $statistics_mediawiki_directory,
        origin    => 'https://gerrit.wikimedia.org/r/p/mediawiki/core.git',
        owner     => 'mwdeploy',
        group     => 'wikidev',
    }

    include ::passwords::mysql::research
    # This file will render at
    # /etc/mysql/conf.d/stats-research-client.cnf.
    mysql::config::client { 'stats-research':
        user  => $::passwords::mysql::research::user,
        pass  => $::passwords::mysql::research::pass,
        group => $::statistics::user::username,
        mode  => '0440',
    }

    # Clean up R temporary files which have not been accessed in a week.
    tidy { '/tmp':
        matches => 'Rtmp*',
        age     => '1w',
        rmdirs  => true,
        backup  => false,
        recurse => 1,
    }
}
