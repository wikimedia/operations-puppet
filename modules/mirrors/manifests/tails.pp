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
    require mirrors

    $local_dir = '/srv/mirrors/tails'
    $remote_path = 'mirrors.rsync.tails.boum.org::amnesia-archive/tails/'

    file { $local_dir:
        ensure => directory,
        owner  => 'mirror',
        group  => 'mirror',
        mode   => '0755',
    }

    $rsync_cmd = "/usr/bin/rsync -rt --delete ${remote_path} ${local_dir}"
    cron { 'update-tails-mirror':
        ensure  => present,
        command => "${rsync_cmd} 1>/dev/null 2>/dev/null",
        user    => 'mirror',
        hour    => '*',
        minute  => '15',
    }
}
