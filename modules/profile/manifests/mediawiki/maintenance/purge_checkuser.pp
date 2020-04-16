class profile::mediawiki::maintenance::purge_checkuser {
    profile::mediawiki::periodic_job { 'purge_checkuser':
        command  => '/usr/local/bin/foreachwiki extensions/CheckUser/maintenance/purgeOldData.php',
        interval => '00:00'
    }
}
