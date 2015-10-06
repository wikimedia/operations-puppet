class gerrit::crons {

    cron { 'list_mediawiki_extensions':
    # Gerrit is missing a public list of projects.
    # This hack list MediaWiki extensions repositories
        command => "/bin/ls -1d /var/lib/gerrit2/review_site/git/mediawiki/extensions/*.git | sed 's#.*/##' | sed 's/\\.git//' > /var/www/mediawiki-extensions.txt",
        user    => 'root',
        minute  => [0, 15, 30, 45],
    }

    cron { 'list_reviewer_counts':
    # This is useful information about the distribution of reviewers.
    # Gerrit's rest api doesn't provide an easy way to get this data.
        command => "ssh -p 29418 localhost gerrit gsql --format JSON_SINGLE -c \"'SELECT changes.change_id AS change_id, COUNT(DISTINCT patch_set_approvals.account_id) AS reviewer_count FROM changes LEFT JOIN patch_set_approvals ON (changes.change_id = patch_set_approvals.change_id) GROUP BY changes.change_id'\" > /var/www/reviewer-counts.json",
        user    => 'gerrit2',
        hour    => 1,
    }

    cron { 'clear_gerrit_logs':
    # Gerrit rotates their own logs, but doesn't clean them out
    # Delete logs older than a week
        command => 'find /var/lib/gerrit2/review_site/logs/*.gz -mtime +7 -exec rm {} \\;',
        user    => 'root',
        hour    => 1
    }

    cron { 'jgit_gc':
    # Keep repo sizes sane, so people can be productive
        command => 'ssh -p 29418 localhost gerrit gc --all > /dev/null 2>&1',
        user    => 'gerrit2',
        hour    => 2,
        weekday => 6
    }
}
