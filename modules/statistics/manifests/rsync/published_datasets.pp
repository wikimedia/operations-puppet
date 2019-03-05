# Class: statistics::rsync::published_datasets
#
# Rsyncs $source to $destination/$::hostname using the
# published-datasets-sync script. The destination host is expected to use
# theh statistics::published_datasets class to merge
# $::hostname directories into a single directory.
# This class should be included on the source host, not the
# remote destination host. The remote destination host must be able to accept
# rsyncs from this host at $destination (statistics::published_datasets will
# set this up).
#
class statistics::rsync::published_datasets(
    $destination = 'thorium.eqiad.wmnet::publshed-datasets-destination', # TODO: hiera-ize thorium.eqiad.wmnet
    $source      = '/srv/published-datasets',
) {
    # Create $source directory. This directory will be
    # rsynced to $destination/$::hostname
    file { $source:
        ensure => 'directory',
        owner  => 'root',
        group  => 'wikidev',
        mode   => '0775',
    }
    file { "${source}/README":
        ensure => 'present',
        source => 'puppet:///modules/statistics/published-datasets-readme.txt',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }

    # Install a simple rsync script for published-datasets, so that
    # users can push their work out manually if they want.
    $published_datasets_destination = "${destination}/${::hostname}/"
    file { '/usr/local/bin/published-datasets-sync':
        content => template('statistics/published-datasets-sync.sh.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
    }

    # Rync push published-datasets from this host to $destination,
    # the analytics.wikimedia.org web host.  These will end up at
    # /srv/published-datasets-rsynced/$hostname, and then the hardsync script
    # will sync them into /srv/analytics.wikimedia.org/datasets.
    # See: statistics::sites::analytics.
    cron { 'rsync-published-datasets':
        # -gp preserve group (wikidev, usually) and permissions, but not
        # ownership, as the owner users might not exist on the destination.
        command => '/usr/local/bin/published-datasets-sync -q',
        user    => 'root',
        minute  => '*/15',
        require => [
            File['/usr/local/bin/published-datasets-sync'],
            File[$source],
        ],
    }
}