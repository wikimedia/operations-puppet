# SPDX-License-Identifier: Apache-2.0
class profile::mediawiki::maintenance::purge_loginnotify(
    Stdlib::Unixpath $helmfile_defaults_dir = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
) {
  profile::mediawiki::periodic_job { 'purge_loginnotify':
    command               => '/usr/local/bin/foreachwikiindblist \'private + fishbowl - nonecho\' extensions/LoginNotify/maintenance/purgeSeen.php',
    interval              => '23:00',
    cron_schedule         => '00 23 * * *',
    kubernetes            => true,
    team                  => 'trust-and-safety-product',
    script_label          => 'purgeSeen.php',
    description           => 'Purge expired user IP address information stored by LoginNotify (dblists: private + fishbowl - nonecho)',
    helmfile_defaults_dir => $helmfile_defaults_dir,
  }
}
