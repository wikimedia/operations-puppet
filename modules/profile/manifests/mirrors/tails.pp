# SPDX-License-Identifier: Apache-2.0
# Class: mirrors::tails
#
# This class sets up a Tails mirror
#
# Parameters:
#
# Actions:
#       Populate Tails mirror configuration directory
#
# Requires:
#
# Sample Usage:
#   include mirrors::tails

class profile::mirrors::tails {
    systemd::timer::job { 'update-tails-mirror':
        ensure      => absent,
        user        => 'mirror',
        description => 'update the tails mirror with rsync',
        command     => '/usr/bin/rsync -rt --delete /srv/mirrors/tails rsync.tails.net::amnesia-archive/tails/',
        interval    => {'start' => 'OnUnitInactiveSec', 'interval' => '1h'},
    }

    rsync::server::module { 'tails':
        ensure    => absent,
        path      => '/srv/mirror/tails',
        read_only => 'yes',
        uid       => 'nobody',
        gid       => 'nogroup',
    }
}