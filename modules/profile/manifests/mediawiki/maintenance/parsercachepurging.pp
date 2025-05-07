class profile::mediawiki::maintenance::parsercachepurging(
    Stdlib::Unixpath $helmfile_defaults_dir = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
) {

    $team = 'data-persistence'

    # Every day, Purge entries older than 30d * 86400s/d = 2592000s
    #
    # WARNING: Increasing msleep may cause exponential growth. Deletes must outpace other writes! (T282761)
    #
    profile::mediawiki::periodic_job { 'purge_parsercache_pc1':
        command               => '/usr/local/bin/mwscript purgeParserCache.php --wiki=aawiki --tag pc1 --age=2592000 --msleep 200',
        interval              => '01:00',
        cron_schedule         => '0 1 * * *',
        kubernetes            => true,
        team                  => $team,
        script_label          => 'purgeParserCache.php',
        description           => 'Purge parsercache entries for pc1 once a day at 01:00.',
        helmfile_defaults_dir => $helmfile_defaults_dir,
    }
    profile::mediawiki::periodic_job { 'purge_parsercache_pc2':
        command               => '/usr/local/bin/mwscript purgeParserCache.php --wiki=aawiki --tag pc2 --age=2592000 --msleep 200',
        interval              => '01:00',
        cron_schedule         => '0 1 * * *',
        kubernetes            => true,
        team                  => $team,
        script_label          => 'purgeParserCache.php',
        description           => 'Purge parsercache entries for pc2 once a day at 01:00.',
        helmfile_defaults_dir => $helmfile_defaults_dir,
    }
    profile::mediawiki::periodic_job { 'purge_parsercache_pc3':
        command               => '/usr/local/bin/mwscript purgeParserCache.php --wiki=aawiki --tag pc3 --age=2592000 --msleep 200',
        interval              => '01:00',
        cron_schedule         => '0 1 * * *',
        kubernetes            => true,
        team                  => $team,
        script_label          => 'purgeParserCache.php',
        description           => 'Purge parsercache entries for pc3 once a day at 01:00.',
        helmfile_defaults_dir => $helmfile_defaults_dir,
    }
    profile::mediawiki::periodic_job { 'purge_parsercache_pc4':
        command               => '/usr/local/bin/mwscript purgeParserCache.php --wiki=aawiki --tag pc4 --age=2592000 --msleep 200',
        interval              => '01:00',
        cron_schedule         => '0 1 * * *',
        kubernetes            => true,
        team                  => $team,
        script_label          => 'purgeParserCache.php',
        description           => 'Purge parsercache entries for pc4 once a day at 01:00.',
        helmfile_defaults_dir => $helmfile_defaults_dir,
    }
    profile::mediawiki::periodic_job { 'purge_parsercache_pc5':
        command               => '/usr/local/bin/mwscript purgeParserCache.php --wiki=aawiki --tag pc5 --age=2592000 --msleep 200',
        interval              => '01:00',
        cron_schedule         => '0 1 * * *',
        kubernetes            => true,
        team                  => $team,
        script_label          => 'purgeParserCache.php',
        description           => 'Purge parsercache entries for pc5 once a day at 01:00.',
        helmfile_defaults_dir => $helmfile_defaults_dir,
    }
    profile::mediawiki::periodic_job { 'purge_parsercache_pc6':
        command               => '/usr/local/bin/mwscript purgeParserCache.php --wiki=aawiki --tag pc6 --age=2592000 --msleep 200',
        interval              => '01:00',
        cron_schedule         => '0 1 * * *',
        kubernetes            => true,
        team                  => $team,
        script_label          => 'purgeParserCache.php',
        description           => 'Purge parsercache entries for pc6 once a day at 01:00.',
        helmfile_defaults_dir => $helmfile_defaults_dir,
    }
    profile::mediawiki::periodic_job { 'purge_parsercache_pc7':
        command               => '/usr/local/bin/mwscript purgeParserCache.php --wiki=aawiki --tag pc7 --age=2592000 --msleep 200',
        interval              => '01:00',
        cron_schedule         => '0 1 * * *',
        kubernetes            => true,
        team                  => $team,
        script_label          => 'purgeParserCache.php',
        description           => 'Purge parsercache entries for pc7 once a day at 01:00.',
        helmfile_defaults_dir => $helmfile_defaults_dir,
    }

}
