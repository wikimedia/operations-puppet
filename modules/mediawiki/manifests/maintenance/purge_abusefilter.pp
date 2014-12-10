########################################################################
#
# Maintenance scripts should always run as apache and never as mwdeploy.
#
# This is 1) for security reasons and 2) for consistent file ownership
# (if MediaWiki creates (temporary) files, they must be owned by apache)
#
########################################################################

class mediawiki::maintenance::purge_abusefilter( $ensure = present ) {
    cron { 'purge_abusefilteripdata':
        ensure  => $ensure,
        command => '/usr/local/bin/foreachwiki extensions/AbuseFilter/maintenance/purgeOldLogIPData.php >/dev/null 2>&1',
        user    => 'apache',
        hour    => '1',
    }
}

