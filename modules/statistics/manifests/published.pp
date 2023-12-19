# Class: statistics::published
#
# Sets up an rsync module and a cron that runs hardsync
# to merge multiple source directories into one.
# This allows remote hosts to push datasets here.
#
# This class does not rsync itself except for HDFS.
# * For cluster client hosts it is expected that all
# desired files are pushed into $hardsync_source by
# statistics::rsync::published.
# * For HDFS, an hdfs-rsync timer is setup to regularly
# pull from $hdfs_rsync_source into $hdfs_rsync_destination
# Note: $hdfs_rsync_destination should be a subfolder of
# $hardsync_source so that data pulled from HDFS is hardlinked
# in the same way as data from cluster-client hosts.
#
# NOTE: $hard_sync_temp_dir should be set to the same filesystem
# as $hardsync_source, as hardsync uses hardlinks to do the merging
# of $hardsync_source/* directories.
#
class statistics::published(
    $hardsync_destination,
    $hardsync_source        = '/srv/published-rsynced',
    $hardsync_temp_dir      = '/srv',
    $hdfs_rsync_destination = '/srv/published-rsynced/analytics-hadoop/',
    $hdfs_rsync_source      = '/wmf/data/published/'
) {
    require statistics::user

    # Pull $hdfs_rsync_source onto $hdfs_rsync_destination
    hdfs_tools::hdfs_rsync_job { 'analytics_hadoop_published':
        hdfs_source       => $hdfs_rsync_source,
        local_destination => $hdfs_rsync_destination,
        interval          => '*:0/15',
        # Requires that the analytics user exists and has a keytab on this host.
        user              => 'analytics',
    }

    # Use hardsync script to hardlink merge files from various host 'published'
    # directories.  These are rsync pushed here from those hosts.
    file { $hardsync_source:
        ensure => 'directory',
        owner  => 'root',
        group  => 'www-data',
        mode   => '0775',
    }

    # Set up an rsync module
    # (in /etc/rsyncd.conf) for /srv.
    rsync::server::module { 'published-destination':
        path        => $hardsync_source,
        read_only   => 'no',
        list        => 'yes',
        hosts_allow => $::statistics::servers,
        auto_nft    => true,
        uid         => $::statistics::user::username,
        gid         => 'wikidev',
        require     => File[$hardsync_source],
    }

    # Merge files in published-rsynced/* via hardlinks into $document_root/published
    systemd::timer::job { 'hardsync-published':
        ensure      => present,
        user        => 'root',
        description => 'Merge files in published-rsynced/* via hardlinks into $document_root/published',
        command     => "/usr/local/bin/hardsync -t ${hardsync_temp_dir} ${hardsync_source}/* ${hardsync_destination}",
        interval    => {'start' => 'OnCalendar', 'interval' => '*:0/15'},
    }
}
