class dataset::cron::rsync (
    $source = undef,
    $enable = true,
    $dest   = undef,
    $user   = 'root',
    $hour   = undef,
    $minute = undef,
)
{
    include dataset::common

    $ensure = $enable ? {
        true    => 'present',
        default => 'absent',
    }

    $rsync_args = '-rt --delete --bwlimit=50000'
    if ($enable) {
        cron { "${title}_rsync":
            ensure      => $ensure,
            user        => $user,
            minute      => $minute,
            hour        => $hour,
            command     => "/usr/bin/rsync ${rsync_args} ${source} ${dest}",
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

