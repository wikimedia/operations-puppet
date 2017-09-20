class dumps::web::rsync::nginxlogs (
    $dest   = undef,
)
{
    require_package('rsync')

    $rsync_args = '-rt --perms --chmod=go+r --bwlimit=50000'
    cron { 'rsync_nginxlogs':
        ensure      => 'present',
        user        => 'root',
        minute      => 55,
        hour        => 4,
        command     => "/usr/bin/rsync ${rsync_args} /var/log/nginx/*.gz ${dest}",
        environment => 'MAILTO=ops-dumps@wikimedia.org',
    }
}

