########################################################################
#
# Maintenance scripts should always run as apache and never as mwdeploy.
#
# This is 1) for security reasons and 2) for consistent file ownership
# (if MediaWiki creates (temporary) files, they must be owned by apache)
#
########################################################################

class mediawiki::maintenance::update_flaggedrev_stats( $ensure = present ) {
    file { '/srv/mediawiki/php/extensions/FlaggedRevs/maintenance/wikimedia-periodic-update.sh':
        ensure => $ensure,
        source => 'puppet:///modules/mediawiki/maintenance/wikimedia-periodic-update.sh',
        owner  => 'apache',
        group  => 'wikidev',
        mode   => '0755',
    }

    cron { 'update_flaggedrev_stats':
        ensure  => $ensure,
        command => '/srv/mediawiki/php/extensions/FlaggedRevs/maintenance/wikimedia-periodic-update.sh > /dev/null',
        user    => 'apache',
        hour    => '*/2',
        minute  => '0',
    }
}

