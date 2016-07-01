class gerrit::migration::source {
    $cmd = '/usr/bin/rsync -rlpt rsync://lead::gerrit_git_data /var/lib/gerrit2/review_site/git'
    cron { 'rsync_gerrit_data':
        command => $cmd,
        user    => 'root',
        hour    => [0, 6, 12, 18]
    }
}
