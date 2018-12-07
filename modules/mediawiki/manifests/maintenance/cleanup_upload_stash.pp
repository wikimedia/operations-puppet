class mediawiki::maintenance::cleanup_upload_stash( $ensure = present ) {
    cron { 'cleanup_upload_stash':
        ensure  => $ensure,
        command => '/usr/local/bin/foreachwiki maintenance/cleanupUploadStash.php > /var/log/mediawiki/cleanup_upload_stash.log 2>/var/log/mediawiki/cleanup_upload_stash.err',
        user    => $::mediawiki::users::web,
        hour    => 1,
        minute  => 0,
    }
}

