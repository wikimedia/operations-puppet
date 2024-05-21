# == Class statistics::compute
#
# Class containing common stuff for a statisitics compute node.
#
class statistics::compute(
    Boolean $enable_stat_host_addons = true,
    Optional[String] $mysql_credentials_group = undef,
) {
    Class['::statistics']       -> Class['::statistics::compute']
    Class['::statistics::user'] -> Class['::statistics::compute']

    $working_path = $::statistics::working_path

    if $enable_stat_host_addons {
        # Set up rsync modules for copying files
        # between statistic servers in /srv and /home
        class { '::statistics::rsyncd':
            hosts_allow => $::statistics::servers,
        }

        file { "${::statistics::working_path}/mediawiki":
            ensure => 'directory',
            owner  => $statistics::user::username,
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
            owner     => $statistics::user::username,
            group     => 'wikidev',
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

    # This file will render at
    # /etc/mysql/conf.d/stats-research-client.cnf.
    if $mysql_credentials_group {
        include ::passwords::mysql::research
        mariadb::config::client { 'stats-research':
            user  => $::passwords::mysql::research::user,
            pass  => $::passwords::mysql::research::pass,
            group => $mysql_credentials_group,
            mode  => '0440',
        }
    }

    # Install a job to rsync /srv/published => $published_host.
    # The statistics::published class should be included on $published_host.
    class { '::statistics::rsync::published': }
    $published_path = $::statistics::rsync::published::source


}
