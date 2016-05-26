# == Class: raid
#
# Class to set up monitoring for software and hardware RAID
#
# === Parameters
#
# === Examples
#
#  include raid

class raid {
    # this line can be removed entirely on a system with:
    # - Facter >= 2.0
    # - Puppet with stringify_facts=false (if supported)
    $raid = split($::raid, ',')

    if 'megaraid' in $raid {
        require_package('megacli')
    }

    if 'mpt' in $raid {
        require_package('mpt-status')

        file { '/etc/default/mpt-statusd':
            ensure  => present,
            owner   => 'root',
            group   => 'root',
            mode    => '0555',
            content => "RUN_DAEMON=no\n",
            before  => Package['mpt-status'],
        }
    }
    if 'md' in $raid {
        # if there is an "md" RAID configured, mdadm is already installed
    }

    if 'aac' in $raid {
        require_package('arcconf')
    }

    if 'twe' in $raid {
        require_package('tw-cli')
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

    nrpe::monitor_service { 'raid':
        description  => 'RAID',
        nrpe_command => '/usr/bin/sudo /usr/local/lib/nagios/plugins/check_raid',
    }
}
