########################################################################
#
# Maintenance scripts should always run as apache and never as mwdeploy.
#
# This is 1) for security reasons and 2) for consistent file ownership
# (if MediaWiki creates (temporary) files, they must be owned by apache)
#
########################################################################

class mediawiki::maintenance::update_special_pages( $ensure = present ) {
    cron { 'update_special_pages':
        ensure   => $ensure,
        command  => 'flock -n /var/lock/update-special-pages /usr/local/bin/update-special-pages > /var/log/mediawiki/updateSpecialPages.log 2>&1',
        user     => 'apache',
        monthday => '*/3',
        hour     => 5,
        minute   => 0,
    }

    file { '/usr/local/bin/update-special-pages':
        ensure => $ensure,
        source => 'puppet:///modules/mediawiki/maintenance/update-special-pages',
        owner  => 'apache',
        group  => 'wikidev',
        mode   => '0755',
    }
}

