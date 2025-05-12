class profile::mediawiki::maintenance::cleanup_upload_stash(
    Stdlib::Unixpath $helmfile_defaults_dir = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
) {

    $team_name = 'mediawiki-file-management'

    profile::mediawiki::periodic_job { 'cleanup_upload_stash':
        command               => '/usr/local/bin/foreachwiki maintenance/cleanupUploadStash.php',
        interval              => '01:00',
        cron_schedule         => '0 1 * * *',
        kubernetes            => true,
        team                  => $team_name,
        script_label          => 'cleanupUploadStash.php',
        description           => 'Remove old or broken uploads from temporary uploaded file storage and database records',
        helmfile_defaults_dir => $helmfile_defaults_dir,
    }
}
