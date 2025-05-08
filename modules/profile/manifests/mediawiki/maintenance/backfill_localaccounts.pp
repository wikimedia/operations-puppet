# SPDX-License-Identifier: Apache-2.0
class profile::mediawiki::maintenance::backfill_localaccounts(
    Stdlib::Unixpath $helmfile_defaults_dir = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
) {
    $team = 'mediawiki-platform'

    # Create missing local accounts on loginwiki, metawiki corresponding to existing global users
    # See T371267
    profile::mediawiki::periodic_job { 'centralauth-backfillLocalAccounts.php-loginwiki':
        command               => '/usr/local/bin/mwscript extensions/CentralAuth/maintenance/backfillLocalAccounts.php  --wiki=loginwiki --startdate=yesterday',
        interval              => '*:25',
        cron_schedule         => '25 * * * *',
        team                  => $team,
        kubernetes            => true,
        description           => 'Backfill global user accounts to loginwiki',
        script_label          => 'CentralAuth-backfillLocalAccounts.php-loginwiki',
        helmfile_defaults_dir => $helmfile_defaults_dir,

    }
    profile::mediawiki::periodic_job { 'centralauth-backfillLocalAccounts.php-metawiki':
        command  => '/usr/local/bin/mwscript extensions/CentralAuth/maintenance/backfillLocalAccounts.php  --wiki=metawiki --startdate=yesterday',
        interval => '*:55',
    }
}
