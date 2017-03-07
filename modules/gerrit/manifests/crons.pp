class gerrit::crons() {
    cron { 'list_mediawiki_extensions':
    # Gerrit is missing a public list of projects.
    # This hack list MediaWiki extensions repositories
        command => "/bin/ls -1d ${::gerrit::jetty::git_dir}/mediawiki/extensions/*.git | sed 's#.*/##' | sed 's/\\.git//' > /var/www/mediawiki-extensions.txt",
        user    => 'root',
        minute  => [0, 15, 30, 45],
    }
}
