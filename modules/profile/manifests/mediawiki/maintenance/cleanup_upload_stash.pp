class profile::mediawiki::maintenance::cleanup_upload_stash {
    profile::mediawiki::periodic_job { 'cleanup_upload_stash':
        command  => '/usr/local/bin/foreachwiki maintenance/cleanupUploadStash.php',
        interval => '01:00',
    }
}
