class profile::mediawiki::maintenance::readinglists(
    Stdlib::Unixpath $helmfile_defaults_dir = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
) {

    $team = 'mediawiki-interfaces'

    profile::mediawiki::periodic_job { 'readinglists_purge':
        command               => '/usr/local/bin/mwscript extensions/ReadingLists/maintenance/purge.php --wiki=metawiki',
        interval              => '02:42',
        cron_schedule         => '42 2 * * *',
        kubernetes            => true,
        team                  => $team,
        script_label          => 'readinglists-purge.php',
        description           => 'Hard-deletes deleted reading lists and entries older than a cutoff date. Also does other DB cleanup that has no effect on functionality.',
        helmfile_defaults_dir => $helmfile_defaults_dir,
    }
}
