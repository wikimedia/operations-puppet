class profile::mediawiki::maintenance::update_flaggedrev_stats(
    Stdlib::Unixpath $helmfile_defaults_dir = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
) {

    profile::mediawiki::periodic_job { 'update_flaggedrev_stats':
        command               => '/usr/local/bin/mwscriptwikiset extensions/FlaggedRevs/maintenance/updateStats.php flaggedrevs.dblist',
        interval              => '00:08',
        cron_schedule         => '08 00 * * *',
        kubernetes            => true,
        team                  => 'flaggedrevs',
        script_label          => 'FlaggedRevs-updateStats.php',
        description           => 'Update the FlaggedRevs article review statistics table',
        helmfile_defaults_dir => $helmfile_defaults_dir,
    }
}
