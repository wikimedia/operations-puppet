# Class: statistics::published
#
# Sets up an rsync module and a cron that runs hardsync
# to merge multiple source directories into one.
# This allows remote hosts to push datasets here.
#
# This class does not rsync itself, it is expected that all
# desired files are pushed into $source by statistics::rsync::published.
#
# NOTE: $temp_dir should be set to the same filesystem as $source, as hardsync
# uses hardlinks to do the merging of $source/* directories.
#
class statistics::published(
    $destination,
    $source   = '/srv/published-rsynced',
    $temp_dir = '/srv'
) {
    require statistics::user

    # Use hardsync script to hardlink merge files from various host 'published'
    # directories.  These are rsync pushed here from those hosts.
    file { $source:
        ensure => 'directory',
        owner  => 'root',
        group  => 'www-data',
        mode   => '0775',
    }

    # Set up an rsync module
    # (in /etc/rsyncd.conf) for /srv.
    rsync::server::module { 'published-destination':
        path        => $source,
        read_only   => 'no',
        list        => 'yes',
        hosts_allow => $::statistics::servers,
        auto_ferm   => true,
        uid         => $::statistics::user::username,
        gid         => 'wikidev',
        require     => File[$source],
    }

    # Merge files in published-rsynced/* via hardlinks into $document_root/published
    systemd::timer::job { 'hardsync-published':
        ensure      => present,
        user        => 'root',
        description => 'Merge files in published-rsynced/* via hardlinks into $document_root/published',
        command     => "/usr/local/bin/hardsync -t ${temp_dir} ${source}/* ${destination}",
        interval    => {'start' => 'OnCalendar', 'interval' => '*:0/15'},
    }

    cron { 'hardsync-published':
        ensure => absent,
        user   => 'root',
    }

}
