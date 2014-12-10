########################################################################
#
# Maintenance scripts should always run as apache and never as mwdeploy.
#
# This is 1) for security reasons and 2) for consistent file ownership
# (if MediaWiki creates (temporary) files, they must be owned by apache)
#
########################################################################

class mediawiki::maintenance::tor_exit_node( $ensure = present ) {
    cron { 'tor_exit_node_update':
        ensure  => $ensure,
        command => '/usr/local/bin/mwscript extensions/TorBlock/loadExitNodes.php --wiki=aawiki --force > /dev/null',
        user    => 'apache',
        minute  => '*/20',
    }
}

