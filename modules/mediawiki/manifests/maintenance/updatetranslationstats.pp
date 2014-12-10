########################################################################
#
# Maintenance scripts should always run as apache and never as mwdeploy.
#
# This is 1) for security reasons and 2) for consistent file ownership
# (if MediaWiki creates (temporary) files, they must be owned by apache)
#
########################################################################

class mediawiki::maintenance::updatetranslationstats( $ensure = present ) {
    # Include this to a maintenance host to update translation stats.

    file { '/usr/local/bin/characterEditStatsTranslate':
        ensure => $ensure,
        owner  => 'mwdeploy',
        group  => 'mwdeploy',
        mode   => '0775',
        source => 'puppet:///modules/mediawiki/maintenance/characterEditStatsTranslate',
    }

    cron { 'updatetranslationstats':
        ensure  => $ensure,
        user    => 'apache',
        minute  => 0,
        hour    => 0,
        weekday => 1,
        command => '/usr/local/bin/characterEditStatsTranslate',
    }
}

