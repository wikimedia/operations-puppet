# sets up cron jobs for Gerrit
class gerrit::crons() {
    cron { 'list_mediawiki_extensions':
    # Gerrit is missing a public list of projects.
    # This hack list MediaWiki extensions repositories
        command => "/bin/ls -1d ${::gerrit::jetty::git_dir}/mediawiki/extensions/*.git | sed 's#.*/##' | sed 's/\\.git//' > /var/www/mediawiki-extensions.txt",
        user    => 'root',
        minute  => [0, 15, 30, 45],
    }

    cron { 'clear_gerrit_logs':
        # Gerrit rotates their own logs, but doesn't clean them out
        # Delete logs older than a week
        command => 'find /var/log/gerrit/ -name "*.gz" -mtime +30 -delete',
        user    => 'root',
        hour    => 1,
    }
}
