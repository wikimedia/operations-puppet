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
        package { [ 'megacli', 'arcconf' ]:
            ensure => 'latest',
        }

        file { '/usr/local/bin/check-raid.py':
            ensure => present,
            owner  => root,
            group  => root,
            mode   => '0555',
            source => 'puppet:///modules/nrpe/plugins/check-raid.py';
        }

        # FIXME: this used to be redundant sudo for check-raid
        # they can be removed when they're deployed across the fleet
        file { [ '/etc/sudoers.d/nrpe', '/etc/sudoers.d/icinga' ]:
            ensure => absent,
        }

        sudo_user { 'nagios':
            privileges   => ['ALL = NOPASSWD: /usr/local/bin/check-raid.py'],
        }
        nrpe::monitor_service { 'raid':
            description  => 'RAID',
            nrpe_command => '/usr/bin/sudo /usr/local/bin/check-raid.py',
        }

        nrpe::monitor_service { 'disk_space':
            description  => 'Disk space',
            nrpe_command => '/usr/lib/nagios/plugins/check_disk -w 6% -c 3% -l -e',
        }
        nrpe::monitor_service { 'dpkg':
            description  => 'DPKG',
            nrpe_command => '/usr/local/lib/nagios/plugins/check_dpkg',
        }
    }
}
