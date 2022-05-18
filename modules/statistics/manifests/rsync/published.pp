# Class: statistics::rsync::published
#
# Rsyncs $source to $destination/$::hostname using the
# published-sync script. The destination host is expected to use
# the statistics::published class to merge
# $::hostname directories into a single directory.
# This class should be included on the source host, not the
# remote destination host. The remote destination host must be able to accept
# rsyncs from this host at $destination (statistics::published will
# set this up).
#
class statistics::rsync::published(
    $destination = 'analytics-web.discovery.wmnet::published-destination',
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
    systemd::timer::job { 'rsync-published':
        ensure      => 'present',
        user        => 'root',
        description => 'Rsync push to analytics.wikimedia.org web host',
        command     => '/usr/local/bin/published-sync -q',
        interval    => {'start' => 'OnCalendar', 'interval' => '*:0/15'},
    }
}
