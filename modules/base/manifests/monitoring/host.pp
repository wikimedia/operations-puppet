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
# $contact_group - Nagios contact_group to use for notifications. Defaults to
# admins
#
class base::monitoring::host($contact_group = 'admins') {
    include base::puppet::params # In order to be able to use some variables

    monitoring::host { $::hostname:
        contact_group => $contact_group
    }
    monitoring::service { 'ssh':
        description   => 'SSH',
        check_command => 'check_ssh',
        contact_group => $contact_group
    }

    package { [ 'megacli', 'arcconf', 'mpt-status' ]:
        ensure => 'latest',
    }

    file { '/etc/default/mpt-statusd':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        content => 'RUN_DAEMON=no',
        require => Package['mpt-status'],
    }

    service { 'mpt-statusd':
        ensure    => stopped,
        enable    => false,
        hasstatus => false,
        stop      => '/usr/bin/pkill -9 -f mpt-statusd',
        require   => Package['mpt-status'],
        subscribe => File['/etc/default/mpt-statusd'],
    }

    file { '/usr/local/bin/check-raid.py':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/base/monitoring/check-raid.py';
    }
    file { '/usr/local/lib/nagios/plugins/check_puppetrun':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/base/monitoring/check_puppetrun';
    }
    file { '/usr/local/lib/nagios/plugins/check_eth':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        content => template('base/check_eth.erb'),
    }
    file { '/usr/lib/nagios/plugins/check_sysctl':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/base/check_sysctl',
    }

    file { '/usr/lib/nagios/plugins/check-fresh-files-in-dir.py':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/base/monitoring/check-fresh-files-in-dir.py',
    }

    sudo::user { 'nagios':
        privileges   => [
                        'ALL = NOPASSWD: /usr/local/bin/check-raid.py',
                        'ALL = NOPASSWD: /usr/local/lib/nagios/plugins/check_puppetrun',
                        ],
    }
    nrpe::monitor_service { 'raid':
        description  => 'RAID',
        nrpe_command => '/usr/bin/sudo /usr/local/bin/check-raid.py',
    }

    # Check for disk usage on the root partition for labs instances
    # This is mapped to the monitoring template - ensure you update
    # labsnagiosbuilder/templates/classes/base.cfg under labs/nagios-builder
    # to reflect this check name
    if $::realm == 'labs' {
        nrpe::monitor_service { 'root_disk_space':
            description  => 'Disk space on /',
            nrpe_command => '/usr/lib/nagios/plugins/check_disk -w 5% -c 2% -l -e -p /',
        }
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
    $warninginterval = $base::puppet::params::freshnessinterval
    $criticalinterval = $base::puppet::params::freshnessinterval * 2
    nrpe::monitor_service { 'puppet_checkpuppetrun':
        description  => 'puppet last run',
        nrpe_command => "/usr/bin/sudo /usr/local/lib/nagios/plugins/check_puppetrun -w ${warninginterval} -c ${criticalinterval}",
    }
    nrpe::monitor_service {'check_eth':
        description  => 'configured eth',
        nrpe_command => '/usr/local/lib/nagios/plugins/check_eth',
    }
    nrpe::monitor_service { 'check_dhclient':
        description  => 'dhclient process',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -w 0:0 -c 0:0 -C dhclient',
    }
    nrpe::monitor_service { 'check_salt_minion':
        description  => 'salt-minion processes',
        nrpe_command => "/usr/lib/nagios/plugins/check_procs -w 1: -c 1:4 --ereg-argument-array '^/usr/bin/python /usr/bin/salt-minion'",
    }
}
