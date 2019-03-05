# == Class statistics::compute
#
# Class containing common stuff for a statisitics compute node.
#
class statistics::compute {
    Class['::statistics']       -> Class['::statistics::compute']
    Class['::statistics::user'] -> Class['::statistics::compute']

    $working_path = $::statistics::working_path

    # Set up rsync modules for copying files
    # between statistic servers in /srv and /home
    class { '::statistics::rsyncd':
        hosts_allow => $::statistics::servers,
    }

    # Install a job to rsync /srv/published-datasets => $published_datasets_host.
    # The statistics::published_datasets class should be included on $published_datasets_host.
    class { '::statistics::rsync::published_datasets': }

    file { "${::statistics::working_path}/mediawiki":
        ensure => 'directory',
        owner  => $::statistics::user,
        group  => 'wikidev',
    }
    # clones mediawiki core at $working_path/mediawiki/core
    # and ensures that it is at the latest revision.
    # T80444
    $statistics_mediawiki_directory = "${::statistics::working_path}/mediawiki/core"
    git::clone { 'statistics_mediawiki':
        ensure    => 'latest',
        directory => $statistics_mediawiki_directory,
        origin    => 'https://gerrit.wikimedia.org/r/p/mediawiki/core.git',
        owner     => $::statistics::user,
        group     => 'wikidev',
    }

    include ::passwords::mysql::research
    # This file will render at
    # /etc/mysql/conf.d/stats-research-client.cnf.
    # NOTE: This file is referenced and used by various
    # reportupdate repository configs, e.g.
    # https://github.com/wikimedia/analytics-limn-ee-data/blob/master/ee/config.yaml
    # If you think about changing or removing this file, make sure you also
    # consider reportupdater's usage.
    mariadb::config::client { 'stats-research':
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
