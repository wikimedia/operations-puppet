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

    $check_raid = '/usr/bin/sudo /usr/local/lib/nagios/plugins/check_raid'

    if 'megaraid' in $raid {
        require_package('megacli')

        nrpe::monitor_service { 'raid_megaraid':
            description  => 'MegaRAID',
            nrpe_command => "${check_raid} megacli",
        }
    }

    if 'hpsa' in $raid {
        require_package('hpssacli')

        file { '/usr/local/lib/nagios/plugins/check_hpssacli':
            ensure => present,
            owner  => 'root',
            group  => 'root',
            mode   => '0555',
            source => 'puppet:///modules/raid/dsa-check-hpssacli',
        }

        sudo::user { 'nagios_hpssacli':
            user       => 'nagios',
            privileges => [
                'ALL = NOPASSWD: /usr/sbin/hpssacli controller all show',
                'ALL = NOPASSWD: /usr/sbin/hpssacli controller slot=[0129] ld all show',
                'ALL = NOPASSWD: /usr/sbin/hpssacli controller slot=[0129] ld [0-9] show',
                'ALL = NOPASSWD: /usr/sbin/hpssacli controller slot=[0129] pd all show',
                'ALL = NOPASSWD: /usr/sbin/hpssacli controller slot=[0129] pd [0-9]\:[0-9] show',
                'ALL = NOPASSWD: /usr/sbin/hpssacli controller slot=[0129] pd [0-9][EIC]\:[0-9]\:[0-9] show',
                'ALL = NOPASSWD: /usr/sbin/hpssacli controller slot=[0129] pd [0-9][EIC]\:[0-9]\:[0-9][0-9] show',
                'ALL = NOPASSWD: /usr/sbin/hpssacli controller slot=[0129] show status',
                'ALL = NOPASSWD: /usr/sbin/hpacucli controller all show',
                'ALL = NOPASSWD: /usr/sbin/hpacucli controller slot=[0129] ld all show',
                'ALL = NOPASSWD: /usr/sbin/hpacucli controller slot=[0129] ld [0-9] show',
                'ALL = NOPASSWD: /usr/sbin/hpacucli controller slot=[0129] pd all show',
                'ALL = NOPASSWD: /usr/sbin/hpacucli controller slot=[0129] pd [0-9]\:[0-9] show',
                'ALL = NOPASSWD: /usr/sbin/hpacucli controller slot=[0129] pd [0-9][EIC]\:[0-9]\:[0-9] show',
                'ALL = NOPASSWD: /usr/sbin/hpacucli controller slot=[0129] pd [0-9][EIC]\:[0-9]\:[0-9][0-9] show',
                'ALL = NOPASSWD: /usr/sbin/hpacucli controller slot=[0129] show status',
            ],
        }

        nrpe::monitor_service { 'raid_hpssacli':
            description  => 'HP RAID',
            nrpe_command => '/usr/local/lib/nagios/plugins/check_hpssacli',
        }
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
