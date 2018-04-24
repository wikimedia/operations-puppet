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
    $nrpe_check_disk_options = '-w 6% -c 3% -W 6% -K 3% -l -e -A -i "/srv/sd[a-b][1-3]" --exclude-type=tracefs',
    $nrpe_check_disk_critical = false,
    $raid_write_cache_policy = undef,
    $raid_check_interval = 10,
    $raid_retry_interval = 10,
    $notifications_enabled = '1',
    $monitor_systemd = true,
) {
    include ::base::puppet::params # In order to be able to use some variables

    # RAID checks
    class { 'raid':
        write_cache_policy => $raid_write_cache_policy,
        check_interval     => $raid_check_interval,
        retry_interval     => $raid_retry_interval,
    }

    ::monitoring::host { $::hostname:
        notifications_enabled => $notifications_enabled,
    }

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
    file { '/usr/lib/nagios/plugins/check_established_connections':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/base/monitoring/check_established_connections.sh',
    }

    file { '/usr/lib/nagios/plugins/check-fresh-files-in-dir.py':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/base/monitoring/check-fresh-files-in-dir.py',
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
        description    => 'puppet last run',
        nrpe_command   => "/usr/bin/sudo /usr/local/lib/nagios/plugins/check_puppetrun -w ${warninginterval} -c ${criticalinterval}",
        check_interval => 5,
        retry_interval => 1,
    }
    ::nrpe::monitor_service {'check_eth':
        description  => 'configured eth',
        nrpe_command => '/usr/local/lib/nagios/plugins/check_eth',
    }
    ::nrpe::monitor_service { 'check_dhclient':
        description  => 'dhclient process',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -w 0:0 -c 0:0 -C dhclient',
    }
    if ($::initsystem == 'systemd') {
        $ensure_monitor_systemd = $monitor_systemd ? {
            true    => present,
            false   => absent,
            default => present,
        }
        file { '/usr/local/lib/nagios/plugins/check_systemd_state':
            ensure => $ensure_monitor_systemd,
            source => 'puppet:///modules/base/check_systemd_state.py',
            owner  => 'root',
            group  => 'root',
            mode   => '0555',
        }
        ::nrpe::monitor_service { 'check_systemd_state':
            ensure       => $ensure_monitor_systemd,
            description  => 'Check systemd state',
            nrpe_command => '/usr/local/lib/nagios/plugins/check_systemd_state',
        }
    }

    if $::productname == 'PowerEdge R320' {

        file { '/usr/local/lib/nagios/plugins/check_cpufreq':
            ensure => present,
            source => 'puppet:///modules/base/monitoring/check_cpufreq',
            owner  => 'root',
            group  => 'root',
            mode   => '0555',
        }

        ::nrpe::monitor_service { 'check_cpufreq':
            description  => 'CPU frequency',
            nrpe_command => '/usr/local/lib/nagios/plugins/check_cpufreq 600',
        }
    }

    if hiera('monitor_screens', true) {

        file { '/usr/local/lib/nagios/plugins/check_long_procs':
            ensure => present,
            source => 'puppet:///modules/base/monitoring/check_long_procs',
            owner  => 'root',
            group  => 'root',
            mode   => '0555',
        }

        ::sudo::user { 'nagios_long_procs':
            user       => 'nagios',
            privileges => ['ALL = NOPASSWD: /usr/local/lib/nagios/plugins/check_long_procs'],
        }

        ::nrpe::monitor_service { 'check_long_procs':
            check_interval => 240,
            retry_interval => 10,
            description    => 'Long running screen/tmux',
            nrpe_command   => '/usr/bin/sudo /usr/local/lib/nagios/plugins/check_long_procs -w 96 -c 480',
        }
    }

    if ! $facts['is_virtual'] {
        monitoring::check_prometheus { 'smart_healthy':
            description     => 'Device not healthy (SMART)',
            dashboard_links => ["https://grafana.wikimedia.org/dashboard/db/host-overview?var-server=${::hostname}&var-datasource=${::site}%20prometheus%2Fops"],
            query           => "device_smart_healthy{instance=\"${::hostname}:9100\"}",
            method          => 'le',
            warning         => 0,
            critical        => 0,
            prometheus_url  => "http://prometheus.svc.${::site}.wmnet/ops",
        }
    }
}
