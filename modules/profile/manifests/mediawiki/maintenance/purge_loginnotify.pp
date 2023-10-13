# SPDX-License-Identifier: Apache-2.0
class profile::mediawiki::maintenance::purge_loginnotify {
  profile::mediawiki::periodic_job { 'purge_loginnotify':
    command  => '/usr/local/bin/foreachwikiindblist \'private + fishbowl + nonglobal - nonecho\' extensions/LoginNotify/maintenance/purgeSeen.php',
    interval => '23:00'
  }
}
