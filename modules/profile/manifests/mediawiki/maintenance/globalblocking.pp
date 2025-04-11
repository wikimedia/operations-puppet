# SPDX-License-Identifier: Apache-2.0
class profile::mediawiki::maintenance::globalblocking(
    Stdlib::Unixpath $helmfile_defaults_dir = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
) {
    # Delete rows from local global_block_whitelist tables if the original block was removed
    profile::mediawiki::periodic_job { 'globalblocking-fixGlobalBlockWhitelist':
        command  => '/usr/local/bin/foreachwiki extensions/GlobalBlocking/maintenance/fixGlobalBlockWhitelist.php  --delete',
        interval => 'Sun 00:00',
    }
}
