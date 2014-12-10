########################################################################
#
# Maintenance scripts should always run as apache and never as mwdeploy.
#
# This is 1) for security reasons and 2) for consistent file ownership
# (if MediaWiki creates (temporary) files, they must be owned by apache)
#
########################################################################

class mediawiki::maintenance::purge_checkuser( $ensure = present ) {
    cron { 'purge-checkuser':
        ensure  => $ensure,
        user    => 'apache',
        minute  => 0,
        hour    => 0,
        weekday => 0,
        command => '/usr/local/bin/foreachwiki extensions/CheckUser/maintenance/purgeOldData.php 2>&1 > /dev/null',
    }
}

