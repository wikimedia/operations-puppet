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
# raid_monitor              - Boolean. Include or not RAID checks.
#
class base::monitoring::host(
    $contact_group = 'admins',
    # the -A -i ... part is a gross hack to workaround Varnish partitions
    # that are purposefully at 99%. Better ideas are welcome.
    $nrpe_check_disk_options = '-w 6% -c 3% -W 6% -K 3% -l -e -A -i "/srv/sd[a-b][1-3]" -i "/srv/nvme[0-9]n[0-9]p[0-9]" --exclude-type=tracefs',
    $nrpe_check_disk_critical = false,
    $raid_write_cache_policy = undef,
    $raid_check_interval = 10,
    $raid_retry_interval = 10,
    $notifications_enabled = '1',
    Boolean $is_critical = false,
    $monitor_systemd = true,
    Integer $puppet_interval = 30,
    Boolean $raid_check = true,
) {
    if $raid_check {
        # RAID checks
        class { 'raid':
            write_cache_policy => $raid_write_cache_policy,
            check_interval     => $raid_check_interval,
            retry_interval     => $raid_retry_interval,
        }
    }

    ::monitoring::host { $::hostname:
        notifications_enabled => $notifications_enabled,
        critical              => $is_critical
    }

    ::monitoring::service { 'ssh':
        description   => 'SSH',
        check_command => 'check_ssh',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/SSH/monitoring',
    }

    # Used by check_puppetrun
    require_package('ruby-safe-yaml')
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
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Monitoring/Disk_space',
    }

    ::nrpe::monitor_service { 'dpkg':
        description  => 'DPKG',
        nrpe_command => '/usr/local/lib/nagios/plugins/check_dpkg',
    }
    # Calculate freshness interval in seconds (hence *60)
    $warninginterval = $puppet_interval * 60 * 6
    $criticalinterval = $warninginterval * 2

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
            nrpe_command   => '/usr/bin/sudo /usr/local/lib/nagios/plugins/check_long_procs -w 240 -c 480',
            notes_url      => 'https://wikitech.wikimedia.org/wiki/Monitoring/Long_running_screens',
        }
    }

    if ! $facts['is_virtual'] {
        monitoring::check_prometheus { 'smart_healthy':
            description     => 'Device not healthy (SMART)',
            dashboard_links => ["https://grafana.wikimedia.org/dashboard/db/host-overview?var-server=${::hostname}&var-datasource=${::site} prometheus/ops"],
            query           => "device_smart_healthy{instance=\"${::hostname}:9100\"}",
            method          => 'le',
            warning         => 0,
            critical        => 0,
            check_interval  => 30,
            retry_interval  => 5,
            retries         => 3,
            prometheus_url  => "http://prometheus.svc.${::site}.wmnet/ops",
            notes_link      => 'https://wikitech.wikimedia.org/wiki/SMART#Alerts',
        }
    }

    # Did an host register an increase in correctable errors over the last 4d? Might indicate faulty
    # memory
    monitoring::check_prometheus { 'edac_correctable_errors':
        description     => 'Memory correctable errors (EDAC)',
        dashboard_links => ["https://grafana.wikimedia.org/dashboard/db/host-overview?orgId=1&var-server=${::hostname}&var-datasource=${::site} prometheus/ops"],
        query           => "sum(increase(node_edac_correctable_errors_total{instance=\"${::hostname}:9100\"}[4d]))",
        warning         => 2,
        critical        => 4,
        check_interval  => 30,
        retry_interval  => 5,
        retries         => 3,
        method          => 'ge',
        prometheus_url  => "http://prometheus.svc.${::site}.wmnet/ops",
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Monitoring/Memory#Memory_correctable_errors_-EDAC-',
    }

    # Did an host log kernel messages from the EDAC subsystem over the last 4d? Might indicate faulty
    # memory.
    # Some of these events are not being caught through the usual node_edac_correctable_errors mechanism:
    # https://phabricator.wikimedia.org/T214529
    monitoring::check_prometheus { 'edac_syslog_events':
        description     => 'EDAC syslog messages',
        dashboard_links => ["https://grafana.wikimedia.org/dashboard/db/host-overview?orgId=1&var-server=${::hostname}&var-datasource=${::site} prometheus/ops"],
        query           => "sum(increase(edac_events{hostname=\"${::hostname}\"}[4d]))",
        warning         => 2,
        critical        => 4,
        check_interval  => 30,
        retry_interval  => 5,
        retries         => 3,
        method          => 'ge',
        prometheus_url  => "http://prometheus.svc.${::site}.wmnet/ops",
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Monitoring/Memory#Memory_correctable_errors_-EDAC-'
    }

    # Alert on reported fs available being bigger than fs size
    # Ideally this would be in check_disk instead, see also https://phabricator.wikimedia.org/T199436
    monitoring::check_prometheus { 'filesystem_avail_bigger_than_size':
        description     => 'Filesystem available is greater than filesystem size',
        dashboard_links => ["https://grafana.wikimedia.org/dashboard/db/host-overview?orgId=1&var-server=${::hostname}&var-datasource=${::site} prometheus/ops"],
        query           => "node_filesystem_avail_bytes{instance=\"${::hostname}:9100\"} > node_filesystem_size_bytes",
        # The query returns node_filesystem_avail_bytes metrics that match the condition. warning/critical
        # are required but placeholders in this case.
        warning         => 1,
        critical        => 2,
        check_interval  => 60,
        retry_interval  => 5,
        retries         => 3,
        method          => 'ge',
        prometheus_url  => "http://prometheus.svc.${::site}.wmnet/ops",
        notes_link      => 'https://phabricator.wikimedia.org/T199436',
    }
}
