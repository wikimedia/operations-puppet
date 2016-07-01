class gerrit::migration::source {
    $cmd = '/usr/bin/rsync -rlpt /var/lib/gerrit2/review_site/git rsync://lead::gerrit_git_data'
    cron { 'rsync_gerrit_data':
        command => $cmd,
        user    => 'root',
        hour    => [0, 6, 12, 18]
    }
}
