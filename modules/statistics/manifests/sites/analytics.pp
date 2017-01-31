# == Class statistics::sites::analytics
# analytics.wikimedia.org
#
# This site will eventually supercede both stats.wikimedia.org
# and datasets.wikimedia.org.  For now it is used to productionize
# various frontend dashboards that have historicaly been running in labs.
#
# Bug: T132407
#
class statistics::sites::analytics {
    require ::statistics::web

    $working_path = $::statistics::working_path
    # /srv/analytics.wikimedia.org
    $document_root = "${working_path}/analytics.wikimedia.org"
    # Allow statistics-web-users to modify files in this directory.

    git::clone { 'analytics.wikimedia.org':
        ensure    => 'latest',
        directory => $document_root,
        origin    => 'https://gerrit.wikimedia.org/r/analytics/analytics.wikimedia.org',
        owner     => 'root',
        group     => 'statistics-web-users',
        mode      => '0775',
    }

    # Use hardsync script to hardlink merge files from various stat box published-dataset
    # directories.  These are rsync pushed here from the stat boxes.
    file { ["${working_path}/published-datasets-rsynced", "${document_root}/datasets"]:
        ensure    => 'directory',
        owner     => 'root',
        group     => 'www-data',
        mode      => '0775',
        require   => Git::Clone['analytics.wikimedia.org'],
    }

    # Merge files in published-datasets-rsynced/* via hardlinks into $document_root/datasets
    cron { 'hardsync-published-datasets':
        # This script is installed by ::statistics::web.
        command => "/usr/local/bin/hardsync -t ${working_path} ${working_path}/published-datasets-rsynced/* ${document_root}/datasets 2>&1 > /dev/null",
        user    => 'root',
        minute  => '*/30',
        require => [
            File["${working_path}/published-datasets-rsynced"],
            File["${document_root}/datasets"]
        ],
    }

    include ::apache::mod::headers
    apache::site { 'analytics':
        content => template('statistics/analytics.wikimedia.org.erb'),
        require => File[$document_root],
    }
}
