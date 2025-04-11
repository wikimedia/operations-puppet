# SPDX-License-Identifier: Apache-2.0

class profile::mediawiki::maintenance::temporary_accounts(
    Stdlib::Unixpath $helmfile_defaults_dir = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
) {

    profile::mediawiki::periodic_job { 'purge_temporary_accounts':
        command  => '/usr/local/bin/foreachwikiindblist "all - closed - private - fishbowl" extensions/CentralAuth/maintenance/expireTemporaryAccounts.php --verbose --frequency 1',
        interval => '*-*-* 14:27:00'
    }
}
