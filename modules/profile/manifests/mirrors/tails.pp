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
    include profile::mirrors

    $local_dir = '/srv/mirrors/tails'
    $remote_path = 'rsync.tails.net::amnesia-archive/tails/'

    file { $local_dir:
        ensure => directory,
        owner  => 'mirror',
        group  => 'mirror',
        mode   => '0755',
    }

    $rsync_cmd = "/usr/bin/rsync -rt --delete ${remote_path} ${local_dir}"

    systemd::timer::job { 'update-tails-mirror':
        ensure      => 'present',
        user        => 'mirror',
        description => 'update the tails mirror with rsync',
        command     => $rsync_cmd,
        interval    => {'start' => 'OnUnitInactiveSec', 'interval' => '1h'},
    }

    # serve via rsync
    rsync::server::module { 'tails':
        path      => $local_dir,
        read_only => 'yes',
        uid       => 'nobody',
        gid       => 'nogroup',
    }

}
