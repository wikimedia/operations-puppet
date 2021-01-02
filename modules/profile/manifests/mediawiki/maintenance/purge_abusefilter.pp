class profile::mediawiki::maintenance::purge_abusefilter {
    profile::mediawiki::periodic_job { 'purge_abusefilteripdata':
        # Remove old name once Ifcc2bff9e40 is deployed everywhere
        command  => '[ -f extensions/AbuseFilter/maintenance/purgeOldLogIPData.php ] && /usr/local/bin/foreachwiki extensions/AbuseFilter/maintenance/purgeOldLogIPData.php || /usr/local/bin/foreachwiki extensions/AbuseFilter/maintenance/PurgeOldLogIPData.php',
        interval => '01:15'
    }
}
