class mediawiki::maintenance::cleanup_upload_stash( $ensure = present ) {
    cron { 'cleanup_upload_stash':
        ensure  => $ensure,
        command => '/usr/local/bin/foreachwiki maintenance/cleanupUploadStash.php > /dev/null 2>&1',
        user    => $::mediawiki::users::web,
        hour    => 1,
        minute  => 0,
    }
}

