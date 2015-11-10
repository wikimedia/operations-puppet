class mediawiki::maintenance::purge_checkuser( $ensure = present ) {
    cron { 'purge-checkuser':
        ensure  => $ensure,
        user    => $::mediawiki::users::web,
        minute  => 0,
        hour    => 0,
        weekday => 0,
        command => '/usr/local/bin/foreachwiki extensions/CheckUser/maintenance/purgeOldData.php >/dev/null 2>&1',
    }
}
