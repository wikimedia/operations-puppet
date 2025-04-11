class profile::mediawiki::maintenance::purge_securepoll(
    Stdlib::Unixpath $helmfile_defaults_dir = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
) {
    profile::mediawiki::periodic_job { 'purge_securepollvotedata':
        command  => '/usr/local/bin/foreachwiki extensions/SecurePoll/cli/purgePrivateVoteData.php',
        interval => '01:00'
    }
}
