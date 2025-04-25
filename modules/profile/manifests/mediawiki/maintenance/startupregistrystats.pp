class profile::mediawiki::maintenance::startupregistrystats(
    Stdlib::Unixpath $helmfile_defaults_dir = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
) {
    $team = 'mediawiki-platform'
    # group0: test.wikipedia.org
    profile::mediawiki::periodic_job { 'startupregistrystats-testwiki':
        command               => '/usr/local/bin/mwscript extensions/WikimediaMaintenance/blameStartupRegistry.php --wiki testwiki --record-stats',
        interval              => '*:10',
        cron_schedule         => '10 * * * *',
        team                  => $team,
        script_label          => 'blameStartupRegistry.php',
        description           => 'Run blameStartupRegistry.php on testwiki at 10 minutes past the hour',
        kubernetes            => true,
        helmfile_defaults_dir => $helmfile_defaults_dir,
    }

    # group0: mediawiki.org
    profile::mediawiki::periodic_job { 'startupregistrystats-mediawikiwiki':
        command               => '/usr/local/bin/mwscript extensions/WikimediaMaintenance/blameStartupRegistry.php --wiki mediawikiwiki --record-stats',
        interval              => '*:15',
        cron_schedule         => '15 * * * *',
        team                  => $team,
        script_label          => 'blameStartupRegistry.php',
        description           => 'Run blameStartupRegistry.php on mediawikiwiki at 15 minutes past the hour',
        kubernetes            => true,
        helmfile_defaults_dir => $helmfile_defaults_dir,
    }

    # large wikis (inludes several group1 and group2 wikis)
    profile::mediawiki::periodic_job { 'startupregistrystats':
        command               => '/usr/local/bin/foreachwikiindblist large extensions/WikimediaMaintenance/blameStartupRegistry.php --record-stats',
        interval              => '*:35',
        cron_schedule         => '35 * * * *',
        team                  => $team,
        script_label          => 'blameStartupRegistry.php',
        description           => 'Run blameStartupRegistry.php on several group1 and group2 wikis at 35 minutes past the hour',
        kubernetes            => true,
        helmfile_defaults_dir => $helmfile_defaults_dir,
    }
}
