class profile::mediawiki::maintenance::purge_abusefilter {
    profile::mediawiki::periodic_job { 'purge_abusefilteripdata':
        command  => '/usr/local/bin/foreachwiki extensions/AbuseFilter/maintenance/PurgeOldLogIPData.php',
        interval => '01:15'
    }
}
