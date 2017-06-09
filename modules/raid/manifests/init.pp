# == Class: raid
#
# Class to set up RAID tools for software and hardware RAID
#
# === Parameters
#
# === Examples
#
#  include raid

class raid {
    if 'megaraid' in $facts['raid'] {
        package { 'megacli':
            ensure => present,
        }
    }

    if 'hpsa' in $facts['raid'] {
        package { 'hpssacli':
            ensure => present,
        }
    }

    if 'mpt' in $facts['raid'] {
        package { 'mpt-status':
            ensure => present,
        }

        file { '/etc/default/mpt-statusd':
            ensure  => present,
            owner   => 'root',
            group   => 'root',
            mode    => '0555',
            content => "RUN_DAEMON=no\n",
            before  => Package['mpt-status'],
        }
    }

    if 'md' in $facts['raid'] {
        # if there is an "md" RAID configured, mdadm is already installed
    }
}
