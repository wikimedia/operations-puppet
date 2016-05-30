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
    # unfortunately, we don't support stringify_facts=false yet; when we
    # eventually do, the fact should be adjusted to not join with ",", and the
    # following line should be then removed.
    $raid = split($::raid, ',')

    $check_raid = '/usr/bin/sudo /usr/local/lib/nagios/plugins/check_raid'

    if 'megaraid' in $raid {
        require_package('megacli')

        nrpe::monitor_service { 'raid_megaraid':
            description  => 'MegaRAID',
            nrpe_command => "${check_raid} megacli",
        }
    }

    if 'mpt' in $raid {
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

        nrpe::monitor_service { 'raid_mpt':
            description  => 'MPT RAID',
            nrpe_command => "${check_raid} mpt",
        }
    }
    if 'md' in $raid {
        # if there is an "md" RAID configured, mdadm is already installed

        nrpe::monitor_service { 'raid_md':
            description  => 'MD RAID',
            nrpe_command => "${check_raid} md",
        }
    }

    if 'aac' in $raid {
        require_package('arcconf')

        nrpe::monitor_service { 'raid_aac':
            description  => 'Adaptec RAID',
            nrpe_command => "${check_raid} aac",
        }
    }

    if 'twe' in $raid {
        require_package('tw-cli')

        nrpe::monitor_service { 'raid_twe':
            description  => '3ware TW',
            nrpe_command => "${check_raid} twe",
        }
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
