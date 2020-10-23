# sets up cron jobs for Gerrit
class gerrit::crons() {
    require gerrit::jetty

    cron { 'clear_gerrit_logs':
        # Gerrit rotates their own logs, but doesn't clean them out
        # Delete logs older than 30 days
        command => 'find /var/log/gerrit/ -name "*.gz" -mtime +30 -delete',
        user    => 'root',
        hour    => 1,
    }
}
