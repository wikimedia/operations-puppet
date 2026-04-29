class profile::mediawiki::maintenance::purge_securepoll(
    Stdlib::Unixpath $helmfile_defaults_dir = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
) {
    $team = 'trust-and-safety-product'

    profile::mediawiki::periodic_job { 'purge_securepollvotedata':
        command               => 'FOREACHWIKI_IGNORE_ERRORS=1 /usr/local/bin/foreachwikiindblist "all - fishbowl - closed" extensions/SecurePoll/cli/purgePrivateVoteData.php',
        interval              => '01:00',
        cron_schedule         => '0 1 * * *',
        kubernetes            => true,
        team                  => $team,
        script_label          => 'purgePrivateVoteData.php',
        description           => 'Purge private data from SecurePoll votes',
        helmfile_defaults_dir => $helmfile_defaults_dir,
    }
}
