class profile::mediawiki::maintenance::purge_abusefilter {
    profile::mediawiki::periodic_job { 'purge_abusefilteripdata':
        command  => '/usr/local/bin/foreachwiki extensions/AbuseFilter/maintenance/purgeOldLogIPData.php',
        interval => '01:15'
    }
}
