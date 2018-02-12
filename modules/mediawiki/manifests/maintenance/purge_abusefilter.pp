class mediawiki::maintenance::purge_abusefilter( $ensure = present ) {
    cron { 'purge_abusefilteripdata':
        ensure  => $ensure,
        command => '/usr/local/bin/foreachwiki extensions/AbuseFilter/maintenance/purgeOldLogIPData.php >/var/log/mediawiki/purge_abusefilter.log',
        user    => $::mediawiki::users::web,
        hour    => 1,
        minute  => 15,
    }
}
