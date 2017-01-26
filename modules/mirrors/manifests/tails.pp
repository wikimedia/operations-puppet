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

class mirrors::tails {
    require ::mirrors

    file { '/srv/mirrors/tails':
        ensure => directory,
        owner  => 'mirror',
        group  => 'mirror',
        mode   => '0755',
    }

    $rsync_cmd = '/usr/bin/rsync -rt --delete rsync.torproject.org::amnesia-archive/tails/ /srv/mirrors/tails/'

    cron { 'update-tails-mirror':
        ensure  => present,
        command => "${rsync_cmd} 1>/dev/null 2>/dev/null",
        user    => 'mirror',
        hour    => '*',
        minute  => '15',
    }
}
