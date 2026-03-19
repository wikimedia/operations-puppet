class profile::mediawiki::maintenance::purge_checkuser(
    Stdlib::Unixpath $helmfile_defaults_dir = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
) {
    $team = 'trust-and-safety-product'

    profile::mediawiki::periodic_job { 'purge_checkuser':
        command               => '/usr/local/bin/foreachwikiindblist "all - checkuser-disabled" extensions/CheckUser/maintenance/purgeOldData.php',
        interval              => '00:00',
        cron_schedule         => '0 0 * * *',
        kubernetes            => true,
        team                  => $team,
        script_label          => 'purgeOldData.php',
        description           => 'Purge expired rows in CheckUser and RecentChanges',
        helmfile_defaults_dir => $helmfile_defaults_dir,
    }

    profile::mediawiki::periodic_job { 'purge_recent_changes':
        command               => '/usr/local/bin/foreachwikiindblist "checkuser-disabled" maintenance/purgeRecentChanges.php',
        interval              => '00:00',
        cron_schedule         => '0 0 * * *',
        kubernetes            => true,
        team                  => $team,
        script_label          => 'purgeRecentChanges.php',
        description           => 'Purge expired rows in RecentChanges on wikis without CheckUser',
        helmfile_defaults_dir => $helmfile_defaults_dir,
    }
}
