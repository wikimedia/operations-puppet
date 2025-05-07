class profile::mediawiki::maintenance::purge_expired_userrights(
    Stdlib::Unixpath $helmfile_defaults_dir = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
) {
    $team = 'mediawiki-platform'

    profile::mediawiki::periodic_job { 'purge_expired_userrights':
        command               => '/usr/local/bin/foreachwiki maintenance/purgeExpiredUserrights.php',
        interval              => '*-14,28 06:42',
        cron_schedule         => '42 06 14,28 * *',
        team                  => $team,
        kubernetes            => true,
        description           => 'Remove expired userrights from user_groups table and move them to former_user_groups for all wikis',
        script_label          => 'purgeExpiredUserrights.php',
        helmfile_defaults_dir => $helmfile_defaults_dir,
    }

    # CentralAuth tables are global, we only need to run this on one wiki.
    # I picked meta since that's where all on-wiki CentralAuth actions are done.
    profile::mediawiki::periodic_job { 'purge_expired_global_rights':
        command  => '/usr/local/bin/mwscript extensions/CentralAuth/maintenance/purgeExpiredGlobalRights.php --wiki metawiki',
        interval => '*-3,17 13:23',
    }
}
