# SPDX-License-Identifier: Apache-2.0
class profile::mediawiki::maintenance::globalblocking(
    Stdlib::Unixpath $helmfile_defaults_dir = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
) {
    # team label for alerting
    $team_label = 'trust-and-safety-product'

    profile::mediawiki::periodic_job { 'globalblocking-fixGlobalBlockWhitelist':
        # dblists must be in sync with $wmgUseGlobalBlocking in mediawiki-config
        command                 => '/usr/local/bin/foreachwikiindblist "all - fishbowl - private - closed" extensions/GlobalBlocking/maintenance/fixGlobalBlockWhitelist.php --delete',
        interval                => 'Sun 00:00',
        cron_schedule           => '0 0 * * SUN',
        team                    => $team_label,
        script_label            => 'fixGlobalBlockWhitelist.php',
        description             => 'Delete rows from local global_block_whitelist tables if the original block was removed',
        kubernetes              => true,
        helmfile_defaults_dir   => $helmfile_defaults_dir,
        ttlsecondsafterfinished => 1209600, # 2 weeks
    }
}
