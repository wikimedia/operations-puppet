class profile::mediawiki::maintenance::cleanup_upload_stash(
    Stdlib::Unixpath $helmfile_defaults_dir = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
) {
    profile::mediawiki::periodic_job { 'cleanup_upload_stash':
        command  => '/usr/local/bin/foreachwiki maintenance/cleanupUploadStash.php',
        interval => '01:00',
    }
}
