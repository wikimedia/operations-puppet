# == Class base::monitoring::host
# Sets up base Nagios monitoring for the host.  This includes
# - ping
# - ssh
# - dpkg
# - disk space
# - raid
#
# Note that this class is probably already included for your node
# by the class base.  If you want to change the contact_group, set
# the variable $nagios_contact_group in your node definition.
# class base will use this variable as the $contact_group argument
# when it includes this class.
#
# == Parameters
# $contact_group - Nagios contact_group to use for notifications.
#                  contact groups are defined in contactgroups.cfg.  Default: "admins"
#
class base::monitoring::host($contact_group = 'admins') {
    monitor_host { $::hostname: group => $::nagios_group, contact_group => $contact_group }
    monitor_service { 'ssh': description => 'SSH', check_command => 'check_ssh', contact_group => $contact_group }

    if $::network_zone == 'internal' {
        package { [ 'megacli', 'arcconf', 'mpt-status' ]:
            ensure => 'latest',
        }

        file { '/etc/default/mpt-statusd':
            ensure  => present,
            owner   => 'root',
            group   => 'root',
            mode    => '0555',
            content => 'RUN_DAEMON=no',
        }

        service { 'mpt-statusd':
            ensure      => stopped,
            enable      => false,
            hasstatus   => false,
            stop        => '/usr/bin/pkill -9 -f mpt-statusd',
        }

        file { '/usr/local/bin/check-raid.py':
            ensure => present,
            owner  => root,
            group  => root,
            mode   => '0555',
            source => 'puppet:///modules/base/monitoring/check-raid.py';
        }
        file { '/usr/local/lib/nagios/plugins/check_puppet_disabled':
            ensure => present,
            owner  => root,
            group  => root,
            mode   => '0555',
            source => 'puppet:///modules/base/monitoring/check_puppet_disabled';
        }

        sudo::user { 'nagios':
            privileges   => ['ALL = NOPASSWD: /usr/local/bin/check-raid.py'],
        }
        nrpe::monitor_service { 'raid':
            description  => 'RAID',
            nrpe_command => '/usr/bin/sudo /usr/local/bin/check-raid.py',
        }

        # the -A -i ... part is a gross hack to workaround Varnish partitions
        # that are purposefully at 99%. Better ideas are welcome.
        nrpe::monitor_service { 'disk_space':
            description  => 'Disk space',
            nrpe_command => '/usr/lib/nagios/plugins/check_disk -w 6% -c 3% -l -e -A -i "/srv/sd[a-b][1-3]"',
        }

        nrpe::monitor_service { 'dpkg':
            description  => 'DPKG',
            nrpe_command => '/usr/local/lib/nagios/plugins/check_dpkg',
        }
        nrpe::monitor_service { 'puppet_disabled':
            description  => 'puppet disabled',
            nrpe_command => '/usr/local/lib/nagios/plugins/check_puppet_disabled',
        }
    }
}
