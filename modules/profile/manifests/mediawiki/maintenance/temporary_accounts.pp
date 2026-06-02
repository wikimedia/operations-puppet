# SPDX-License-Identifier: Apache-2.0

class profile::mediawiki::maintenance::temporary_accounts(
    Stdlib::Unixpath $helmfile_defaults_dir = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
) {
    # team label for alerting
    $team_label = 'trust-and-safety-product'

    profile::mediawiki::periodic_job { 'purge_temporary_accounts':
        command               => '/usr/local/bin/foreachwikiindblist "all - closed - private - fishbowl" extensions/CentralAuth/maintenance/expireTemporaryAccounts.php --verbose --frequency 1',
        interval              => '*-*-* 14:27:00',
        cron_schedule         => '27 14 * * *',
        team                  => $team_label,
        kubernetes            => true,
        description           => 'Expire temporary accounts registered before the configured expiry window (dblists: all - closed - private - fishbowl)',
        script_label          => 'CentralAuth-expireTemporaryAccounts.php',
        helmfile_defaults_dir => $helmfile_defaults_dir,
    }

    # CheckUser is not enabled on the beta cluster
    if $::realm != 'labs' {
      profile::mediawiki::periodic_job { 'checkuser_revoke_temporaryaccountviewer':
          command               => '/usr/local/bin/foreachwiki extensions/CheckUser/maintenance/revokeTemporaryAccountViewerGroup.php --expiry 365',
          interval              => '*-*-* 00:00:00',
          cron_schedule         => '00 00 * * *',
          team                  => $team_label,
          kubernetes            => true,
          description           => 'Revoke temporary-account-viewer group membership from users who are considered inactive. See T375115.',
          script_label          => 'CheckUser-revokeTemporaryAccountViewerGroup.php',
          helmfile_defaults_dir => $helmfile_defaults_dir,
      }
    }
}
