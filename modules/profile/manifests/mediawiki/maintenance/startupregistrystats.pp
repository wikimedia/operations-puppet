class profile::mediawiki::maintenance::startupregistrystats(
    Stdlib::Unixpath $helmfile_defaults_dir = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
) {
    # group0: test.wikipedia.org
    profile::mediawiki::periodic_job { 'startupregistrystats-testwiki':
        command               => '/usr/local/bin/mwscript extensions/WikimediaMaintenance/blameStartupRegistry.php --wiki testwiki --record-stats',
        interval              => '*:10',
        cron_schedule         => '*/10 * * * *',
        team                  => 'mediawiki-platform',
        script_label          => 'blameStartupRegistry.php',
        description           => 'Run blameStartupRegistry.php on testwiki every 10 minutes',
        kubernetes            => true,
        helmfile_defaults_dir => $helmfile_defaults_dir,
    }

    # group0: mediawiki.org
    profile::mediawiki::periodic_job { 'startupregistrystats-mediawikiwiki':
        command  => '/usr/local/bin/mwscript extensions/WikimediaMaintenance/blameStartupRegistry.php --wiki mediawikiwiki --record-stats',
        interval => '*:15'
    }

    # large wikis (inludes several group1 and group2 wikis)
    profile::mediawiki::periodic_job { 'startupregistrystats':
        command  => '/usr/local/bin/foreachwikiindblist large extensions/WikimediaMaintenance/blameStartupRegistry.php --record-stats',
        interval => '*:35'
    }
}
