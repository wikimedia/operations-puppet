# SPDX-License-Identifier: Apache-2.0

class profile::mediawiki::maintenance::temporary_accounts(
    Stdlib::Unixpath $helmfile_defaults_dir = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
) {

    profile::mediawiki::periodic_job { 'purge_temporary_accounts':
        command               => '/usr/local/bin/foreachwikiindblist "all - closed - private - fishbowl" extensions/CentralAuth/maintenance/expireTemporaryAccounts.php --verbose --frequency 1',
        interval              => '*-*-* 14:27:00',
        cron_schedule         => '27 14 * * *',
        team                  => 'mediawiki-platform',
        kubernetes            => true,
        description           => 'Expire temporary accounts registered before the configured expiry window (dblists: all - closed - private - fishbowl)',
        script_label          => 'CentralAuth-expireTemporaryAccounts.php',
        helmfile_defaults_dir => $helmfile_defaults_dir,
    }
}
