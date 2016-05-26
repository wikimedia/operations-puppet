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
    package { [ 'megacli', 'arcconf', 'mpt-status', 'hpssacli' ]:
        ensure => 'latest',
    }

    file { '/etc/default/mpt-statusd':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        content => "RUN_DAEMON=no\n",
        before  => Package['mpt-status'],
    }

    file { '/usr/local/bin/check-raid.py':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/raid/check-raid.py';
    }

    sudo::user { 'nagios_raid':
        user       => 'nagios',
        privileges => ['ALL = NOPASSWD: /usr/local/bin/check-raid.py'],
    }

    nrpe::monitor_service { 'raid':
        description  => 'RAID',
        nrpe_command => '/usr/bin/sudo /usr/local/bin/check-raid.py',
    }
}
