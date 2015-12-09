class mediawiki::maintenance::cirrussearch( $ensure = present ) {
    require mediawiki::users

    # Rebuilds the completion suggester index once a week. This is scheduled
    # to run during the low period of cirrus usage, which is generally 12am
    # to 7am UTC.
    cron { 'cirrus_build_completion_indices':
        ensure   => $ensure,
        user     => $::mediawiki::users::web,
        minute   => 20,
        hour     => 0,
        weekday  => 2,
        command  => '/usr/local/bin/expanddblist all | xargs -I{} -P 4 sh -c \'mwscript extensions/CirrusSearch/maintenance/updateSuggesterIndex.php --wiki={} --optimize > /var/log/mediawiki/cirrus-suggest/{}.log\''
    }

    file { '/var/log/mediawiki/cirrus-suggest':
        ensure => ensure_directory($ensure),
        owner  => $::mediawiki::users::web,
        group  => $::mediawiki::users::web,
        mode   => '0775'
    }

    file { '/etc/logrotate.d/cirrus-suggest':
        ensure => $ensure,
        source => 'puppet:///modules/mediawiki/maintenance/logrotate.d_cirrus-suggest',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }
}
