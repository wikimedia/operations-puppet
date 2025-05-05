class profile::mediawiki::maintenance::pagetriage(
    Stdlib::Unixpath $helmfile_defaults_dir = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
) {

    $team = 'moderator-tools'

    # TODO: Consider creating a single periodic job that runs all of these scripts at
    # 48h intervals, rather than staggering them throughout the day.
    profile::mediawiki::periodic_job { 'pagetriage_cleanup_en':
        interval              => '*-2/2 20:55',
        command               => '/usr/local/bin/mwscript extensions/PageTriage/cron/updatePageTriageQueue.php enwiki',
        cron_schedule         => '55 20 2-31/2 * *',
        kubernetes            => true,
        team                  => $team,
        script_label          => 'updatePageTriageQueue.php-enwiki',
        description           => 'Removes expired page metadata from the pagetriage queue on enwiki',
        helmfile_defaults_dir => $helmfile_defaults_dir,
    }

    profile::mediawiki::periodic_job { 'pagetriage_cleanup_testwiki':
        interval              => '*-2/2 14:55',
        command               => '/usr/local/bin/mwscript extensions/PageTriage/cron/updatePageTriageQueue.php testwiki',
        cron_schedule         => '55 14 2-31/2 * *',
        kubernetes            => true,
        team                  => $team,
        script_label          => 'updatePageTriageQueue.php-testwiki',
        description           => 'Removes expired page metadata from the pagetriage queue on testwiki',
        helmfile_defaults_dir => $helmfile_defaults_dir,
    }

    profile::mediawiki::periodic_job { 'pagetriage_cleanup_test2wiki':
        interval              => '*-2/2 8:55',
        cron_schedule         => '55 8 2-31/2 * *',
        kubernetes            => true,
        team                  => $team,
        script_label          => 'updatePageTriageQueue.php-test2wiki',
        description           => 'Removes expired page metadata from the pagetriage queue on test2wiki',
        command               => '/usr/local/bin/mwscript extensions/PageTriage/cron/updatePageTriageQueue.php test2wiki',
        helmfile_defaults_dir => $helmfile_defaults_dir,
    }
}
