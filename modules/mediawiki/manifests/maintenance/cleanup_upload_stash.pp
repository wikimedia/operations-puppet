class mediawiki::maintenance::cleanup_upload_stash( $ensure = present ) {
    mediawiki::cron { 'cleanup_upload_stash':
        ensure  => $ensure,
        command => '/usr/local/bin/foreachwiki maintenance/cleanupUploadStash.php > /dev/null',
        user    => $::mediawiki::users::web,
        hour    => 1,
        minute  => 0,
    }
}
