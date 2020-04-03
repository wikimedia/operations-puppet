class profile::mediawiki::maintenance::updatetranslationstats {
    # Include this to a maintenance host to update translation stats.

    file { '/usr/local/bin/characterEditStatsTranslate':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/profile/mediawiki/maintenance/characterEditStatsTranslate',
    }

    profile::mediawiki::periodic_job { 'updatetranslationstats':
        command  => '/usr/local/bin/characterEditStatsTranslate',
        interval => 'Mon 00:00',
    }
}
