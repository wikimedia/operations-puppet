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

    $published_datasets_path = "${working_path}/published-datasets"
    # Create $working_path/published-datasets.  Anything in this directory
    # will be available at analytics.wikimedia.org/datasets.
    # See: class statistics::sites::analytics.
    file { $published_datasets_path:
        ensure => 'directory',
        owner  => 'root',
        group  => 'wikidev',
        mode   => '0775',
    }
    file { "${published_datasets_path}/README":
        ensure => 'present',
        source => 'puppet:///modules/statistics/published-datasets-readme.txt',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }

    # Install a simple rsync script for published-datasets, so that
    # stat users can push their work out manually if they want.
    # TODO: hiera-ize thorium.eqiad.wmnet
    $published_datasets_destination = "thorium.eqiad.wmnet::publshed-datasets-destination/${::hostname}/"
    file { '/usr/local/bin/published-datasets-sync':
        content => template('statistics/published-datasets-sync.sh.erb'),
        owner   => 'root',
        group   => 'root',
        mode    =>  '0755',
    }

    # Rync push published-datasets from this host to thorium,
    # the analytics.wikimedia.org web host.  These will end up at
    # /srv/published-datasets-rsynced/$hostname, and then the hardsync script
    # will sync them into /srv/analytics.wikimedia.org/datasets.
    # See: statistics::sites::analytics.
    cron { 'rsync-published-datasets':
        # -gp preserve group (wikidev, usually) and permissions, but not
        # ownership, as the owner users might not exist on the destination.
        command => '/usr/local/bin/published-datasets-sync -q',
        require => [File['/usr/local/bin/published-datasets-sync'], File[$published_datasets_path]],
        user    => 'root',
        minute  => '*/15',
    }

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
