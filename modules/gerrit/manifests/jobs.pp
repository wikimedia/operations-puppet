# sets up periodic jobs for Gerrit
class gerrit::jobs {

    systemd::timer::job { 'clear_gerrit_logs':
        ensure      => 'present',
        user        => 'root',
        description => 'Gerrit rotates their own logs, but does not clean them out. Delete old logs.',
        command     => "/usr/bin/find /var/log/gerrit/ -name \"*.gz\" -mtime +30 -delete",
        interval    => {'start' => 'OnCalendar', 'interval' => 'daily'},
    }

}
