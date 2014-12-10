########################################################################
#
# Maintenance scripts should always run as apache and never as mwdeploy.
#
# This is 1) for security reasons and 2) for consistent file ownership
# (if MediaWiki creates (temporary) files, they must be owned by apache)
#
########################################################################

class mediawiki::maintenance::purge_securepoll( $ensure = present ) {
    cron { 'purge_securepollvotedata':
        ensure  => $ensure,
        user    => 'apache',
        hour    => '1',
        command => '/usr/local/bin/foreachwiki extensions/SecurePoll/cli/purgePrivateVoteData.php 2>&1 > /dev/null',
    }
}
