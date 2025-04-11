# SPDX-License-Identifier: Apache-2.0
class profile::mediawiki::maintenance::purge_loginnotify(
    Stdlib::Unixpath $helmfile_defaults_dir = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
) {
  profile::mediawiki::periodic_job { 'purge_loginnotify':
    command  => '/usr/local/bin/foreachwikiindblist \'private + fishbowl - nonecho\' extensions/LoginNotify/maintenance/purgeSeen.php',
    interval => '23:00'
  }
}
