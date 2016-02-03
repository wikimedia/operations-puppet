class dataset::cron::rsync::nginxlogs (
    $enable = true,
    $dest   = undef,
    $user   = 'root',
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
            minute      => 55,
            hour        => 4,
            command     => "/usr/bin/rsync ${rsync_args} /var/log/nginx/ ${dest}",
            environment => 'MAILTO=ops-dumps@wikimedia.org',
            require     => User[$user],
        }
    }
    else {
        cron { "/var/log/nginx_${dest}_rsync":
            ensure      => absent,
        }
    }
}

