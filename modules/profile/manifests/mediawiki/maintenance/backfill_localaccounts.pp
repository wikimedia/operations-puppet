# SPDX-License-Identifier: Apache-2.0
class profile::mediawiki::maintenance::backfill_localaccounts(
    Stdlib::Unixpath $helmfile_defaults_dir = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
) {
    # Create missing local accounts on loginwiki, metawiki corresponding to existing global users
    # See T371267
    profile::mediawiki::periodic_job { 'centralauth-backfillLocalAccounts.php-loginwiki':
        command  => '/usr/local/bin/mwscript extensions/CentralAuth/maintenance/backfillLocalAccounts.php  --wiki=loginwiki --startdate=yesterday',
        interval => '*:25',
    }
    profile::mediawiki::periodic_job { 'centralauth-backfillLocalAccounts.php-metawiki':
        command  => '/usr/local/bin/mwscript extensions/CentralAuth/maintenance/backfillLocalAccounts.php  --wiki=metawiki --startdate=yesterday',
        interval => '*:55',
    }
}
