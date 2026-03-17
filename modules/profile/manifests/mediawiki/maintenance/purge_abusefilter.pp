class profile::mediawiki::maintenance::purge_abusefilter(
    Stdlib::Unixpath $helmfile_defaults_dir = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
) {
    $team = 'trust-and-safety-product'

    profile::mediawiki::periodic_job { 'purge_abusefilteripdata':
        command               => '/usr/local/bin/foreachwikiindblist "all - abusefilter-disabled" extensions/AbuseFilter/maintenance/PurgeOldLogIPData.php',
        interval              => '01:15',
        cron_schedule         => '15 1 * * *',
        kubernetes            => true,
        team                  => $team,
        script_label          => 'PurgeOldLogIPData.php',
        description           => 'Purge old abusefilter IP log data',
        helmfile_defaults_dir => $helmfile_defaults_dir,
    }
}
