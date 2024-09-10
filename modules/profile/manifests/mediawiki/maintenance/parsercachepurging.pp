class profile::mediawiki::maintenance::parsercachepurging {

    # Every day, Purge entries older than 30d * 86400s/d = 2592000s
    #
    # WARNING: Increasing msleep may cause exponential growth. Deletes must outpace other writes! (T282761)
    #
    profile::mediawiki::periodic_job { 'purge_parsercache_pc1':
        command  => '/usr/local/bin/mwscript purgeParserCache.php --wiki=aawiki --tag pc1 --age=2592000 --msleep 200',
        interval => '01:00',
    }
    profile::mediawiki::periodic_job { 'purge_parsercache_pc2':
        command  => '/usr/local/bin/mwscript purgeParserCache.php --wiki=aawiki --tag pc2 --age=2592000 --msleep 200',
        interval => '01:00',
    }
    profile::mediawiki::periodic_job { 'purge_parsercache_pc3':
        command  => '/usr/local/bin/mwscript purgeParserCache.php --wiki=aawiki --tag pc3 --age=2592000 --msleep 200',
        interval => '01:00',
    }

    profile::mediawiki::periodic_job { 'purge_parsercache_pc4':
        command  => '/usr/local/bin/mwscript purgeParserCache.php --wiki=aawiki --tag pc4 --age=2592000 --msleep 200',
        interval => '01:00',
    }
    profile::mediawiki::periodic_job { 'purge_parsercache_pc5':
        command  => '/usr/local/bin/mwscript purgeParserCache.php --wiki=aawiki --tag pc5 --age=2592000 --msleep 200',
        interval => '01:00',
    }
}
