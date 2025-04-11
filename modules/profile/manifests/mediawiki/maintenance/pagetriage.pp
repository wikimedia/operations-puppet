class profile::mediawiki::maintenance::pagetriage(
    Stdlib::Unixpath $helmfile_defaults_dir = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
) {
    # TODO: Consider creating a single periodic job that runs all of these scripts at
    # 48h intervals, rather than staggering them throughout the day.
    profile::mediawiki::periodic_job { 'pagetriage_cleanup_en':
        interval => '*-2/2 20:55',
        command  => '/usr/local/bin/mwscript extensions/PageTriage/cron/updatePageTriageQueue.php enwiki',
    }

    profile::mediawiki::periodic_job { 'pagetriage_cleanup_testwiki':
        interval => '*-2/2 14:55',
        command  => '/usr/local/bin/mwscript extensions/PageTriage/cron/updatePageTriageQueue.php testwiki',
    }

    profile::mediawiki::periodic_job { 'pagetriage_cleanup_test2wiki':
        interval => '*-2/2 8:55',
        command  => '/usr/local/bin/mwscript extensions/PageTriage/cron/updatePageTriageQueue.php test2wiki',
    }
}
