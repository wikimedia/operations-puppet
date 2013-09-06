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
        file { '/usr/local/bin/check-raid.py':
            ensure => present,
            owner  => root,
            group  => root,
            mode   => '0555',
            source => 'puppet:///modules/base/monitoring/check-raid.py';
        }

        sudo_user { [ 'nagios', 'icinga' ]: privileges => ['ALL = NOPASSWD: /usr/local/bin/check-raid.py'] }
        nrpe::monitor_service { 'raid' : description => 'RAID', nrpe_command  => 'sudo /usr/local/bin/check-raid.py' }
        nrpe::monitor_service { 'disk_space' : description => 'Disk space', nrpe_command  => '/usr/lib/nagios/plugins/check_disk -w 6% -c 3% -l -e' }
        nrpe::monitor_service { 'dpkg' : description => 'DPKG', nrpe_command  => '/usr/local/lib/nagios/plugins/check_dpkg' }

        ## this is only needed for the raid checks.
        ## should be able to move into sudo_user def above once puppet is caught up
        if $::lsbdistid == 'Ubuntu' and versioncmp($::lsbdistrelease, '10.04') >= 0 {
            file { '/etc/sudoers.d/nrpe':
                owner   => root,
                group   => root,
                mode    => '0440',
                content => "
nagios  ALL = (root) NOPASSWD: /usr/local/bin/check-raid.py
icinga  ALL = (root) NOPASSWD: /usr/local/bin/check-raid.py
nagios  ALL = (root) NOPASSWD: /usr/bin/arcconf getconfig 1
icinga  ALL = (root) NOPASSWD: /usr/bin/arcconf getconfig 1
";
            }
        }
    }
}
