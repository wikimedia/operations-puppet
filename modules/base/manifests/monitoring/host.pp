# == Class base::monitoring::host
# Sets up base Nagios monitoring for the host.  This includes
# - ping
# - ssh
# - dpkg
# - disk space
# - raid
# - ipmi
#
# Note that this class is probably already included for your node
# by the class base.  If you want to change the contact_group, set
# the variable contactgroups in hiera.
# class base will use this variable as the $contact_group argument
# when it includes this class.
#
# == Parameters
# $contact_group            - Nagios contact_group to use for notifications. Defaults to
#                             admins
#
# nrpe_check_disk_options   - Default options for checking disks.  Defaults to checking
#                             all disks and warning at < 6% and critical at < 3% free.
#
# nrpe_check_disk_critical  - Make disk space alerts paging, defaults to not paging
#
class base::monitoring::host(
    $contact_group = 'admins',
    # the -A -i ... part is a gross hack to workaround Varnish partitions
    # that are purposefully at 99%. Better ideas are welcome.
    $nrpe_check_disk_options = '-w 6% -c 3% -l -e -A -i "/srv/sd[a-b][1-3]" --exclude-type=tracefs',
    $nrpe_check_disk_critical = false,
) {
    include ::base::puppet::params # In order to be able to use some variables

    # RAID checks
    include ::raid

    ::monitoring::host { $::hostname: }

    ::monitoring::service { 'ssh':
        description   => 'SSH',
        check_command => 'check_ssh',
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

    file { '/usr/local/lib/nagios/plugins/check_ipmi_sensor':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/base/monitoring/check_ipmi_sensor',
    }

    ::sudo::user { 'nagios_puppetrun':
        user       => 'nagios',
        privileges => ['ALL = NOPASSWD: /usr/local/lib/nagios/plugins/check_puppetrun'],
    }

    # Check for disk usage on the root partition for labs instances
    # This is mapped to the monitoring template - ensure you update
    # labsnagiosbuilder/templates/classes/base.cfg under labs/nagios-builder
    # to reflect this check name
    if $::realm == 'labs' {
        ::nrpe::monitor_service { 'root_disk_space':
            description  => 'Disk space on /',
            nrpe_command => '/usr/lib/nagios/plugins/check_disk -w 5% -c 2% -l -e -p /',
        }
    }

    ::nrpe::monitor_service { 'disk_space':
        description  => 'Disk space',
        critical     => $nrpe_check_disk_critical,
        nrpe_command => "/usr/lib/nagios/plugins/check_disk ${nrpe_check_disk_options}",
    }

    ::nrpe::monitor_service { 'dpkg':
        description  => 'DPKG',
        nrpe_command => '/usr/local/lib/nagios/plugins/check_dpkg',
    }
    $warninginterval = $base::puppet::params::freshnessinterval
    $criticalinterval = $base::puppet::params::freshnessinterval * 2
    ::nrpe::monitor_service { 'puppet_checkpuppetrun':
        description  => 'puppet last run',
        nrpe_command => "/usr/bin/sudo /usr/local/lib/nagios/plugins/check_puppetrun -w ${warninginterval} -c ${criticalinterval}",
    }
    ::nrpe::monitor_service {'check_eth':
        description  => 'configured eth',
        nrpe_command => '/usr/local/lib/nagios/plugins/check_eth',
    }
    ::nrpe::monitor_service { 'check_dhclient':
        description  => 'dhclient process',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -w 0:0 -c 0:0 -C dhclient',
    }
    ::nrpe::monitor_service { 'check_salt_minion':
        description  => 'salt-minion processes',
        nrpe_command => "/usr/lib/nagios/plugins/check_procs -w 1: -c 1:4 --ereg-argument-array '^/usr/bin/python /usr/bin/salt-minion'",
    }
    if $::initsystem == 'systemd' {
        file { '/usr/local/lib/nagios/plugins/check_systemd_state':
            ensure => present,
            source => 'puppet:///modules/base/check_systemd_state.py',
            owner  => 'root',
            group  => 'root',
            mode   => '0555',
        }
        ::nrpe::monitor_service { 'check_systemd_state':
            description  => 'Check systemd state',
            nrpe_command => '/usr/local/lib/nagios/plugins/check_systemd_state',
        }
    }
}
