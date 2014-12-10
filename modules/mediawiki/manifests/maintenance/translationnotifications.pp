########################################################################
#
# Maintenance scripts should always run as apache and never as mwdeploy.
#
# This is 1) for security reasons and 2) for consistent file ownership
# (if MediaWiki creates (temporary) files, they must be owned by apache)
#
########################################################################

class mediawiki::maintenance::translationnotifications( $ensure = present ) {
    # Should there be crontab entry for each wiki,
    # or just one which runs the scripts which iterates over
    # selected set of wikis?

    cron { 'translationnotifications-metawiki':
        ensure  => $ensure,
        user    => 'apache',
        command => '/usr/local/bin/mwscript extensions/TranslationNotifications/scripts/DigestEmailer.php --wiki metawiki 2>&1 >> /var/log/mediawiki/translationnotifications/digests.log',
        weekday => 1, # Monday
        hour    => 10,
        minute  => 0,
    }

    cron { 'translationnotifications-mediawikiwiki':
        ensure  => $ensure,
        user    => 'apache',
        command => '/usr/local/bin/mwscript extensions/TranslationNotifications/scripts/DigestEmailer.php --wiki mediawikiwiki 2>&1 >> /var/log/mediawiki/translationnotifications/digests.log',
        weekday => 1, # Monday
        hour    => 10,
        minute  => 5,
    }

    file { '/var/log/translationnotifications':
        ensure => ensure_directory($ensure),
        owner  => 'apache',
        group  => 'wikidev',
        mode   => '0664',
    }

    file { '/etc/logrotate.d/l10nupdate':
        ensure => $ensure,
        source => 'puppet:///modules/mediawiki/maintenance/translationnotifications',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }
}

