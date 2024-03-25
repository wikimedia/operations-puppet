# SPDX-License-Identifier: Apache-2.0
class profile::mediawiki::maintenance::purge_flaggedrevs {
    profile::mediawiki::periodic_job { 'purge_flaggedtemplates':
        ensure   => absent,
        command  => '/usr/local/bin/foreachwikiindblist flaggedrevs extensions/FlaggedRevs/maintenance/pruneRevData.php',
        interval => '*-01,04,07,10-7 01:01:01'
    }
}
