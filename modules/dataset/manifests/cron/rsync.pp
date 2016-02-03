class dataset::cron::rsync (
    $source = '/var/log/nginx/',
    $enable = true,
    $dest   = undef,
    $user   = 'root',
    $hour   = undef,
    $minute = undef,
)
{
    include dataset::common

    if ($enable) {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    $rsync_args = '-rt --delete --bwlimit=50000'
    if ($enable) {
        cron { "${source}_${dest}_rsync":
            ensure      => $ensure,
            user        => $user,
            minute      => $minute,
            hour        => $hour,
            command     => "/usr/bin/rsync ${rsync_args} ${source}/ ${dest}/",
            environment => 'MAILTO=ops-dumps@wikimedia.org',
            require     => User[$user],
        }
    }
    else {
        cron { "${source}_${dest}_rsync":
            ensure      => absent,
        }
    }
}

