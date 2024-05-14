class dumps::web::rsync::nginxlogs (
    String $dest           = undef,
    Wmflib::Ensure $ensure = present,
) {
    ensure_packages('rsync')

    $rsync_args = '--include "*.gz" --exclude "*" -rt --perms --chmod=go+r --bwlimit=50000'
    systemd::timer::job { 'rsync_nginxlogs':
        ensure             => $ensure,
        description        => 'Regular jobs to rsync nginx logs',
        user               => 'root',
        monitoring_enabled => false,
        send_mail          => true,
        environment        => {'MAILTO' => 'ops-dumps@wikimedia.org'},
        command            => "/usr/bin/rsync ${rsync_args} /var/log/nginx/ ${dest}",
        interval           => {'start' => 'OnCalendar', 'interval' => '*-*-* 4:55:0'},
    }
}
