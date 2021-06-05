class dumps::web::rsync::nginxlogs (
    $dest   = undef,
)
{
    ensure_packages('rsync')

    $rsync_args = '-rt --perms --chmod=go+r --bwlimit=50000'
    systemd::timer::job { 'rsync_nginxlogs':
        ensure             => present,
        description        => 'Regular jobs to rsync nginx logs',
        user               => 'root',
        monitoring_enabled => false,
        send_mail          => true,
        environment        => {'MAILTO' => 'ops-dumps@wikimedia.org'},
        command            => "/usr/bin/rsync ${rsync_args} /var/log/nginx/*.gz ${dest}",
        interval           => {'start' => 'OnCalendar', 'interval' => '*-*-* 4:55:0'},
    }
}

