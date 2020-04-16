class profile::mediawiki::maintenance::purge_expired_userrights {
    profile::mediawiki::periodic_job { 'purge_expired_userrights':
        command  => '/usr/local/bin/foreachwiki maintenance/purgeExpiredUserrights.php',
        interval => '*-14,28 06:42'
    }
}
