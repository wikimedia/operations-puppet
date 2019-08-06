class mediawiki::maintenance::startupregistrystats(
    $ensure = present
) {
    cron { 'startupregistrystats':
        ensure  => $ensure,
        user    => $::mediawiki::users::web,
        minute  => 35,
        command => '/usr/local/bin/foreachwikiindblist large extensions/WikimediaMaintenance/blameStartupRegistry.php --record-stats > /dev/null 2>&1',
    }
}
