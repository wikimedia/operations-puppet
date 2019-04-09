# Class: statistics::published_datasets
#
# Sets up an rsync module and a cron that runs hardsync
# to merge multiple source directories into one.
# This allows remote hosts to push datasets here.
#
# This class does not rsync itself, it is expected that all
# desired files are pushed into $source by statistics::rsync::published_datasets.
#
# NOTE: $temp_dir should be set to the same filesystem as $source, as hardsync
# uses hardlinks to do the merging of $source/* directories.
#
class statistics::published_datasets(
    $destination,
    $source   = '/srv/published-datasets-rsynced',
    $temp_dir = '/srv'
) {
    require statistics::user

    # Use hardsync script to hardlink merge files from various host published-dataset
    # directories.  These are rsync pushed here from those those hosts.
    file { $source:
        ensure => 'directory',
        owner  => 'root',
        group  => 'www-data',
        mode   => '0775',
    }

    # Set up an rsync module
    # (in /etc/rsyncd.conf) for /srv.
    rsync::server::module { 'publshed-datasets-destination':
        path        => $source,
        read_only   => 'no',
        list        => 'yes',
        hosts_allow => $::statistics::servers,
        auto_ferm   => true,
        uid         => $::statistics::user::username,
        gid         => 'wikidev',
        require     => File[$source],
    }

    # Merge files in published-datasets-rsynced/* via hardlinks into $document_root/datasets
    cron { 'hardsync-published-datasets':
        # This script is installed by ::statistics::web.
        command => "/usr/local/bin/hardsync -t ${temp_dir} ${source}/* ${destination} 2>&1 > /dev/null",
        user    => 'root',
        minute  => '*/15',
        require => File[$source],
    }

}