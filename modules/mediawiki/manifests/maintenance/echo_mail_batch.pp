########################################################################
#
# Maintenance scripts should always run as apache and never as mwdeploy.
#
# This is 1) for security reasons and 2) for consistent file ownership
# (if MediaWiki creates (temporary) files, they must be owned by apache)
#
########################################################################

class mediawiki::maintenance::echo_mail_batch( $ensure = present ) {
    cron { 'echo_mail_batch':
        ensure  => $ensure,
        command => '/usr/local/bin/foreachwikiindblist /srv/mediawiki/echowikis.dblist extensions/Echo/maintenance/processEchoEmailBatch.php 2>/dev/null',
        user    => 'apache',
        minute  => 0,
        hour    => 0,
    }
}

