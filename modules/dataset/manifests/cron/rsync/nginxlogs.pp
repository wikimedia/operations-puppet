class dataset::cron::rsync::nginxlogs (
    $enable = true,
    $dest   = undef,
    $user   = 'root',
)
{
    include ::dataset::common

    $ensure = $enable ? {
        true    => 'present',
        default => 'absent',
    }

    $rsync_args = '-rt --perms --chmod=go+r --bwlimit=50000'
    cron { 'rsync_nginxlogs':
        ensure      => $ensure,
        user        => $user,
        minute      => 55,
        hour        => 4,
        command     => "/usr/bin/rsync ${rsync_args} /var/log/nginx/*.gz ${dest}",
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        require     => User[$user],
    }
}

