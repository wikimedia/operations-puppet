# Class: statistics::rsync::published
#
# Rsyncs $source to $destination/$::hostname using the
# published-sync script. The destination host is expected to use
# theh statistics::published class to merge
# $::hostname directories into a single directory.
# This class should be included on the source host, not the
# remote destination host. The remote destination host must be able to accept
# rsyncs from this host at $destination (statistics::published will
# set this up).
#
class statistics::rsync::published(
    $destination = 'thorium.eqiad.wmnet::published-destination', # TODO: hiera-ize thorium.eqiad.wmnet
    $source      = '/srv/published',
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
        source => 'puppet:///modules/statistics/published-readme.txt',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }

    # Install a simple rsync script for published data, so that
    # users can push their work out manually if they want.
    $published_destination = "${destination}/${::hostname}/"
    file { '/usr/local/bin/published-sync':
        content => template('statistics/published-sync.sh.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
    }

    # Rync push $source from this host to $destination,
    # the analytics.wikimedia.org web host.  These will end up at
    # /srv/published-rsynced/$hostname, and then the hardsync script
    # will sync them into /srv/analytics.wikimedia.org/published.
    # See: statistics::sites::analytics.
    cron { 'rsync-published':
        # -gp preserve group (wikidev, usually) and permissions, but not
        # ownership, as the owner users might not exist on the destination.
        command => '/usr/local/bin/published-sync -q',
        user    => 'root',
        minute  => '*/15',
        require => [
            File['/usr/local/bin/published-sync'],
            File[$source],
        ],
    }
}