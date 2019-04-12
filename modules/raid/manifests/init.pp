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
        $check_raid = '/usr/bin/sudo /usr/local/lib/nagios/plugins/check_raid'
    } else {
        $check_raid = "/usr/bin/sudo /usr/local/lib/nagios/plugins/check_raid --policy ${write_cache_policy}"
    }

    if 'megaraid' in $facts['raid'] {
      include raid::megaraid
    }

    if 'hpsa' in $facts['raid'] {
      include raid::hpsa
    }

    if 'mpt' in $facts['raid'] {
      include raid::mpt
    }

    if 'md' in $facts['raid'] {
      include raid::md
    }

    file { '/usr/local/lib/nagios/plugins/check_raid':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/raid/check-raid.py';
    }

    sudo::user { 'nagios_raid':
        user       => 'nagios',
        privileges => ['ALL = NOPASSWD: /usr/local/lib/nagios/plugins/check_raid'],
    }
}
