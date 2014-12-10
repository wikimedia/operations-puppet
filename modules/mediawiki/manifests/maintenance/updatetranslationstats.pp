
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
        user    => $::mediawiki::users::web,
        minute  => 0,
        hour    => 0,
        weekday => 1,
        command => '/usr/local/bin/characterEditStatsTranslate >/dev/null',
    }
}

