
class mediawiki::maintenance::update_flaggedrev_stats( $ensure = present ) {
    file { '/srv/mediawiki/php/extensions/FlaggedRevs/maintenance/wikimedia-periodic-update.sh':
        ensure => $ensure,
        source => 'puppet:///modules/mediawiki/maintenance/wikimedia-periodic-update.sh',
        owner  => $::mediawiki::users::web,
        group  => 'wikidev',
        mode   => '0755',
    }

    cron { 'update_flaggedrev_stats':
        ensure  => $ensure,
        command => '/srv/mediawiki/php/extensions/FlaggedRevs/maintenance/wikimedia-periodic-update.sh > /dev/null',
        user    => $::mediawiki::users::web,
        hour    => '*/2',
        minute  => '0',
    }
}

