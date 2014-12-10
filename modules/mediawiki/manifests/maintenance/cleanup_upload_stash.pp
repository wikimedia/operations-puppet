########################################################################
#
# Maintenance scripts should always run as apache and never as mwdeploy.
#
# This is 1) for security reasons and 2) for consistent file ownership
# (if MediaWiki creates (temporary) files, they must be owned by apache)
#
########################################################################

class mediawiki::maintenance::cleanup_upload_stash( $ensure = present ) {
    cron { 'cleanup_upload_stash':
        ensure  => $ensure,
        command => '/usr/local/bin/foreachwiki maintenance/cleanupUploadStash.php > /dev/null',
        user    => 'apache',
        hour    => 1,
        minute  => 0,
    }
}

