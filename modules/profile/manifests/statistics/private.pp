# == Class profile::statistics::private
#
class profile::statistics::private(
    $statistics_servers  = hiera('statistics_servers'),
    $statsd_host         = hiera('statsd'),
    $graphite_host       = hiera('profile::statistics::private::graphite_host'),
    $wmde_secrets        = hiera('wmde_secrets'),
    $dumps_servers       = hiera('dumps_dist_nfs_servers'),
    $dumps_active_server = hiera('dumps_dist_active_web'),
) {

    require ::profile::analytics::cluster::packages::statistics

    class {'::deployment::umask_wikidev': }

    class { '::statistics':
        servers      => $statistics_servers,
    }

    # include stuff common to statistics compute nodes
    class { '::statistics::compute': }

    class { '::statistics::dataset_mount':
        dumps_servers       => $dumps_servers,
        dumps_active_server => $dumps_active_server,
    }

    # Directory to host datasets that are generated locally and synced over
    # via rsync fetch jobs running on the dumps distribution servers
    file {'/srv/dumps':
        ensure => 'directory',
        mode   => '0775',
        owner  => 'stats',
        group  => 'wikidev',
    }

    # This file will render at
    # /etc/mysql/conf.d/statistics-private-client.cnf.
    # This is so that users in the statistics-privatedata-users
    # group who want to access the research slave dbs do not
    # have to be in the research group, which is not included
    # in the private role.
    statistics::mysql_credentials { 'statistics-private':
        group => 'statistics-privatedata-users',
    }

    # Include the MySQL research password at
    # /etc/mysql/conf.d/analytics-research-client.cnf
    # and only readable by users in the
    # analytics-privatedata-users group.
    statistics::mysql_credentials { 'analytics-research':
        group => 'analytics-privatedata-users',
    }

    # The eventlogging codebase is useful for scripting
    # EventLogging consumers.  Install this but don't run any daemons.
    class { '::eventlogging': }

    # EventLogging Analytics data logs are not private, but they
    # are rsynced here for convenience and backup redundancy.
    class { '::statistics::rsync::eventlogging': }

    # rsync mediawiki logs from logging hosts
    class { '::statistics::rsync::mediawiki': }

    if $::hostname == 'stat1007' {
        # Class to save old versions of the geoip MaxMind database, which are useful
        # for historical geocoding.
        if !defined(File['/srv/geoip']) {
            file { '/srv/geoip':
                ensure => directory,
                owner  => 'root',
                group  => 'wikidev',
            }
        }
        class { '::geoip::data::archive':
            archive_dir => '/srv/geoip/archive',
            require     => File['/srv/geoip'],
        }

        # Discovery team statistics scripts and cron jobs
        class { '::statistics::discovery': }
    }

    if $::hostname == 'stat1005' {

        # WMDE releated statistics & analytics scripts.
        class { '::statistics::wmde':
            statsd_host   => $statsd_host,
            graphite_host => $graphite_host,
            wmde_secrets  => $wmde_secrets,
        }

    }
}
