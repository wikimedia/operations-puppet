class profile::mediawiki::maintenance::initsitestats(
    Stdlib::Unixpath $helmfile_defaults_dir = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
) {
    $team_name = 'mediawiki-special-pages'

    profile::mediawiki::periodic_job { 'initsitestats':
        command               => '/usr/local/bin/foreachwiki initSiteStats.php --update',
        interval              => '*-*-* 21:00:00',
        cron_schedule         => '0 21 * * *',
        kubernetes            => true,
        team                  => $team_name,
        script_label          => 'initSiteStats.php',
        description           => 'Re-initialise or update the site statistics table.',
        helmfile_defaults_dir => $helmfile_defaults_dir,
    }
}
