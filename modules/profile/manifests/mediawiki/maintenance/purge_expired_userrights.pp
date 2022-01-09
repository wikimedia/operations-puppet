class profile::mediawiki::maintenance::purge_expired_userrights {
    profile::mediawiki::periodic_job { 'purge_expired_userrights':
        command  => '/usr/local/bin/foreachwiki maintenance/purgeExpiredUserrights.php',
        interval => '*-14,28 06:42'
    }

    # CentralAuth tables are global, we only need to run this on one wiki.
    # I picked meta since that's where all on-wiki CentralAuth actions are done.
    profile::mediawiki::periodic_job { 'purge_expired_global_rights':
        command  => '/usr/local/bin/mwscript extensions/CentralAuth/maintenance/purgeExpiredGlobalRights.php --wiki metawiki',
        interval => '*-3,17 13:23',
    }
}
