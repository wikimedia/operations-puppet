# SPDX-License-Identifier: Apache-2.0
# == Class: raid
#
# Class to set up monitoring for software and hardware RAID
#
# === Parameters
# * write_cache_policy: if set, it will check that the write cache
#                       policy of all logical drives matches the one
#                       given, normally 'WriteBack' or 'WriteThrough'.
#                       Currently only works for Megacli systems, it is
#                       ignored in all other cases.
# === Examples
#
#  include raid

class raid (
    $write_cache_policy = undef,
    $check_interval = 10,
    $retry_interval = 10,
){

    if empty($write_cache_policy) {
        $check_raid = '/usr/local/lib/nagios/plugins/check_raid'
    } else {
        $check_raid = "/usr/local/lib/nagios/plugins/check_raid --policy ${write_cache_policy}"
    }

    if 'raid_mgmt_tools' in $facts {
        $facts['raid_mgmt_tools'].each |String $raid| {
            include "raid::${raid}"
        }
    } else {
        warning('no raid controller detected')
    }

    nrpe::plugin { 'check_raid':
        source => 'puppet:///modules/raid/check-raid.py';
    }
}
