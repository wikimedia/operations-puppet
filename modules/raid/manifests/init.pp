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

    # for 'forking' checks (i.e. all but mdadm, which essentially just reads
    # kernel memory from /proc/mdstat) check every $check_interval
    # minutes instead of default of one minute. If the check is non-OK, retry
    # every $retry_interval.
    $check_interval = 10
    $retry_interval = 5

    if 'megaraid' in $raid {
        require_package('megacli')
        $get_raid_status_megacli = '/usr/local/lib/nagios/plugins/get-raid-status-megacli'

        file { $get_raid_status_megacli:
            ensure => present,
            owner  => 'root',
            group  => 'root',
            mode   => '0555',
            source => 'puppet:///modules/raid/get-raid-status-megacli.py';
        }

        sudo::user { 'nagios_megaraid':
            user       => 'nagios',
            privileges => ["ALL = NOPASSWD: ${get_raid_status_megacli}"],
        }

        nrpe::check { 'get_raid_status_megacli':
            command => "/usr/bin/sudo ${get_raid_status_megacli} -c",
        }

        nrpe::monitor_service { 'raid_megaraid':
            description    => 'MegaRAID',
            nrpe_command   => "${check_raid} megacli",
            check_interval => $check_interval,
            retry_interval => $retry_interval,
            event_handler  => "raid_handler!megacli!${::site}",
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
                'ALL = NOPASSWD: /usr/sbin/hpssacli controller slot=[0-9] ld all show',
                'ALL = NOPASSWD: /usr/sbin/hpssacli controller slot=[0-9] ld all show detail',
                'ALL = NOPASSWD: /usr/sbin/hpssacli controller slot=[0-9] ld * show',
                'ALL = NOPASSWD: /usr/sbin/hpssacli controller slot=[0-9] pd all show',
                'ALL = NOPASSWD: /usr/sbin/hpssacli controller slot=[0-9] pd [0-9]\:[0-9] show',
                'ALL = NOPASSWD: /usr/sbin/hpssacli controller slot=[0-9] pd [0-9][EIC]\:[0-9]\:[0-9] show',
                'ALL = NOPASSWD: /usr/sbin/hpssacli controller slot=[0-9] pd [0-9][EIC]\:[0-9]\:[0-9][0-9] show',
                'ALL = NOPASSWD: /usr/sbin/hpssacli controller slot=[0-9] show status',
                'ALL = NOPASSWD: /usr/sbin/hpacucli controller all show',
                'ALL = NOPASSWD: /usr/sbin/hpacucli controller slot=[0-9] ld all show',
                'ALL = NOPASSWD: /usr/sbin/hpacucli controller slot=[0-9] ld * show',
                'ALL = NOPASSWD: /usr/sbin/hpacucli controller slot=[0-9] pd all show',
                'ALL = NOPASSWD: /usr/sbin/hpacucli controller slot=[0-9] pd [0-9]\:[0-9] show',
                'ALL = NOPASSWD: /usr/sbin/hpacucli controller slot=[0-9] pd [0-9][EIC]\:[0-9]\:[0-9] show',
                'ALL = NOPASSWD: /usr/sbin/hpacucli controller slot=[0-9] pd [0-9][EIC]\:[0-9]\:[0-9][0-9] show',
                'ALL = NOPASSWD: /usr/sbin/hpacucli controller slot=[0-9] show status',
            ],
        }

        nrpe::monitor_service { 'raid_hpssacli':
            description    => 'HP RAID',
            nrpe_command   => '/usr/local/lib/nagios/plugins/check_hpssacli',
            timeout        => 50, # can take > 10s on servers with lots of disks
            check_interval => $check_interval,
            retry_interval => $retry_interval,
            event_handler  => "raid_handler!hpssacli!${::site}",
        }

        $get_raid_status_hpssacli = '/usr/local/lib/nagios/plugins/get-raid-status-hpssacli'

        file { $get_raid_status_hpssacli:
            ensure => present,
            owner  => 'root',
            group  => 'root',
            mode   => '0555',
            source => 'puppet:///modules/raid/get-raid-status-hpssacli.sh';
        }

        nrpe::check { 'get_raid_status_hpssacli':
            command => "${get_raid_status_hpssacli} -c",
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
            description    => 'MPT RAID',
            nrpe_command   => "${check_raid} mpt",
            check_interval => $check_interval,
            retry_interval => $retry_interval,
            event_handler  => "raid_handler!mpt!${::site}",
        }

        nrpe::check { 'get_raid_status_mpt':
            command => "${check_raid} mpt",
        }
    }

    if 'md' in $raid {
        # if there is an "md" RAID configured, mdadm is already installed

        nrpe::monitor_service { 'raid_md':
            description   => 'MD RAID',
            nrpe_command  => "${check_raid} md",
            event_handler => "raid_handler!md!${::site}",
        }

        nrpe::check { 'get_raid_status_md':
            command => 'cat /proc/mdstat',
        }
    }

    if 'aac' in $raid {
        require_package('arcconf')

        nrpe::monitor_service { 'raid_aac':
            description    => 'Adaptec RAID',
            nrpe_command   => "${check_raid} aac",
            check_interval => $check_interval,
            retry_interval => $retry_interval,
        }
    }

    if 'twe' in $raid {
        require_package('tw-cli')

        nrpe::monitor_service { 'raid_twe':
            description    => '3ware TW',
            nrpe_command   => "${check_raid} twe",
            check_interval => $check_interval,
            retry_interval => $retry_interval,
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
