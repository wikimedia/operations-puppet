# SPDX-License-Identifier: Apache-2.0

class profile::mediawiki::maintenance::temporary_accounts {

    profile::mediawiki::periodic_job { 'purge_temporary_accounts':
        command  => '/usr/local/bin/foreachwikiindblist "all - closed - private - fishbowl - nonglobal" extensions/CentralAuth/maintenance/expireTemporaryAccounts.php --verbose --frequency 1',
        interval => '*-*-* 14:27:00'
    }
}
