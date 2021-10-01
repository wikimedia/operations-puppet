# @summary profile to configure icinga monitoring host
#   Sets up base Nagios monitoring for the host.  This includes
#   - ping
#   - ssh
#   - dpkg
#   - disk space
#   - raid
#   - ipmi
#
#   Note that this class is probably already included for your node
#   by the class base.  If you want to change the contact_group, set
#   the variable contactgroups in hiera.
#   class base will use this variable as the $contact_group argument
#   when it includes this class.
#
# @param hardware_monitoring indicate if we should monitor HW
# @param contact_group Nagios contact_group to use for notifications.
# @param mgmt_contact_group Nagios contact_group to use for notifications related to the drac/ilo interface.
# @param notifications_enabled inticate if we should send notifications
# @param is_critical indicate this host is critical
# @param monitor_systemd indicate if we should monitor systemd
# @param monitor_screens indicate if we should monitor screens
# @param puppet_interval interval for puppet checks
# @param nrpe_check_disk_options Default options for checking disks.  Defaults to checking
#   all disks and warning at < 6% and critical at < 3% free.
# @param check_raid indicate if we should check raid
# @param nrpe_check_disk_critical Make disk space alerts paging, defaults to not paging
# @parma raid_check_interval check interval for raid checks
# @parma raid_retry_interval retry interval for raid retrys
class profile::monitoring (
    Wmflib::Ensure $hardware_monitoring = lookup('profile::monitoring::hardware_monitoring'),
    # TODO: make this an array
    String $contact_group               = lookup('profile::monitoring::contact_group'),
    String $mgmt_contact_group          = lookup('profile::monitoring::mgmt_contact_group'),
    Boolean $is_critical                = lookup('profile::monitoring::is_critical'),
    Boolean $monitor_systemd            = lookup('profile::monitoring::monitor_systemd'),
    String $nrpe_check_disk_options     = lookup('profile::monitoring::nrpe_check_disk_options'),
    Boolean $nrpe_check_disk_critical   = lookup('profile::monitoring::nrpe_check_disk_critical'),
    Boolean $raid_check                 = lookup('profile::monitoring::raid_check'),
    Integer $raid_check_interval        = lookup('profile::monitoring::raid_check_interval'),
    Integer $raid_retry_interval        = lookup('profile::monitoring::raid_retry_interval'),
    Boolean $notifications_enabled      = lookup('profile::monitoring::notifications_enabled'),
    Optional[Enum['WriteThrough', 'WriteBack']] $raid_write_cache_policy = lookup('profile::monitoring::raid_write_cache_policy')
) {
    ensure_packages('ruby-safe-yaml')

    include profile::base::puppet
    $puppet_interval = $profile::base::puppet::interval

    if $raid_check and $hardware_monitoring == 'present'{
        # RAID checks
        class { 'raid':
            write_cache_policy => $raid_write_cache_policy,
            check_interval     => $raid_check_interval,
            retry_interval     => $raid_retry_interval,
        }
    }

    monitoring::host { $facts['hostname']:
        notifications_enabled => $notifications_enabled,
        critical              => $is_critical,
        mgmt_contact_group    => $mgmt_contact_group
    }

    monitoring::service { 'ssh':
        description   => 'SSH',
        check_command => 'check_ssh',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/SSH/monitoring',
    }

    file {
        default:
            ensure => present,
            owner  => 'root',
            group  => 'root',
            mode   => '0555';
        '/usr/local/lib/nagios/plugins/check_puppetrun':
            source => 'puppet:///modules/base/monitoring/check_puppetrun.rb';
        '/usr/local/lib/nagios/plugins/check_eth':
            content => template('base/check_eth.erb');
        '/usr/lib/nagios/plugins/check_sysctl':
            source => 'puppet:///modules/base/check_sysctl';
        '/usr/lib/nagios/plugins/check_established_connections':
            source => 'puppet:///modules/base/monitoring/check_established_connections.sh';
        '/usr/lib/nagios/plugins/check-fresh-files-in-dir.py':
            source => 'puppet:///modules/base/monitoring/check-fresh-files-in-dir.py';
    }

    sudo::user { 'nagios_puppetrun':
        user       => 'nagios',
        privileges => ['ALL = NOPASSWD: /usr/local/lib/nagios/plugins/check_puppetrun'],
    }

    nrpe::monitor_service { 'disk_space':
        description     => 'Disk space',
        critical        => $nrpe_check_disk_critical,
        nrpe_command    => "/usr/lib/nagios/plugins/check_disk ${nrpe_check_disk_options}",
        notes_url       => 'https://wikitech.wikimedia.org/wiki/Monitoring/Disk_space',
        dashboard_links => ["https://grafana.wikimedia.org/dashboard/db/host-overview?var-server=${facts['hostname']}&var-datasource=${::site} prometheus/ops"],
        check_interval  => 20,
        retry_interval  => 5,
    }

    nrpe::monitor_service { 'dpkg':
        description    => 'DPKG',
        nrpe_command   => '/usr/local/lib/nagios/plugins/check_dpkg',
        notes_url      => 'https://wikitech.wikimedia.org/wiki/Monitoring/dpkg',
        check_interval => 30,
    }

    # Calculate freshness interval in seconds (hence *60)
    $warninginterval = $puppet_interval * 60 * 6
    $criticalinterval = $warninginterval * 2

    nrpe::monitor_service { 'puppet_checkpuppetrun':
        description    => 'puppet last run',
        nrpe_command   => "/usr/bin/sudo /usr/local/lib/nagios/plugins/check_puppetrun -w ${warninginterval} -c ${criticalinterval}",
        check_interval => 5,
        retry_interval => 1,
        notes_url      => 'https://wikitech.wikimedia.org/wiki/Monitoring/puppet_checkpuppetrun',
    }
    nrpe::monitor_service {'check_eth':
        description    => 'configured eth',
        nrpe_command   => '/usr/local/lib/nagios/plugins/check_eth',
        notes_url      => 'https://wikitech.wikimedia.org/wiki/Monitoring/check_eth',
        check_interval => 30,
    }
    nrpe::monitor_service { 'check_dhclient':
        description    => 'dhclient process',
        nrpe_command   => '/usr/lib/nagios/plugins/check_procs -w 0:0 -c 0:0 -C dhclient',
        notes_url      => 'https://wikitech.wikimedia.org/wiki/Monitoring/check_dhclient',
        check_interval => 30,
    }

    $ensure_monitor_systemd = $monitor_systemd.bool2str('present','absent')

    file { '/usr/local/lib/nagios/plugins/check_systemd_state':
        ensure => $ensure_monitor_systemd,
        source => 'puppet:///modules/base/check_systemd_state.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    nrpe::monitor_service { 'check_systemd_state':
        ensure       => $ensure_monitor_systemd,
        description  => 'Check systemd state',
        nrpe_command => '/usr/local/lib/nagios/plugins/check_systemd_state',
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Monitoring/check_systemd_state',
    }

    if $facts['productname'] == 'PowerEdge R320' {

        file { '/usr/local/lib/nagios/plugins/check_cpufreq':
            ensure => present,
            source => 'puppet:///modules/base/monitoring/check_cpufreq',
            owner  => 'root',
            group  => 'root',
            mode   => '0555',
        }

        nrpe::monitor_service { 'check_cpufreq':
            description  => 'CPU frequency',
            nrpe_command => '/usr/local/lib/nagios/plugins/check_cpufreq 600',
            notes_url    => 'https://wikitech.wikimedia.org/wiki/Monitoring/check_cpufreq',
        }
    }


    # TODO: remove once absented
    file { '/usr/local/lib/nagios/plugins/check_long_procs':
        ensure => absent,
    }

    # TODO: remove once absented
    ::nrpe::monitor_service { 'check_long_procs':
        ensure => 'absent',
    }

    if ! $facts['is_virtual'] {
        monitoring::check_prometheus { 'smart_healthy':
            ensure          => $hardware_monitoring,
            description     => 'Device not healthy (SMART)',
            dashboard_links => ["https://grafana.wikimedia.org/dashboard/db/host-overview?var-server=${facts['hostname']}&var-datasource=${::site} prometheus/ops"],
            contact_group   => $contact_group,
            query           => "device_smart_healthy{instance=\"${facts['hostname']}:9100\"}",
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
        ensure          => $hardware_monitoring,
        description     => 'Memory correctable errors (EDAC)',
        dashboard_links => ["https://grafana.wikimedia.org/dashboard/db/host-overview?orgId=1&var-server=${facts['hostname']}&var-datasource=${::site} prometheus/ops"],
        contact_group   => $contact_group,
        query           => "sum(increase(node_edac_correctable_errors_total{instance=\"${facts['hostname']}:9100\"}[4d]))",
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
        ensure          => $hardware_monitoring,
        description     => 'EDAC syslog messages',
        dashboard_links => ["https://grafana.wikimedia.org/dashboard/db/host-overview?orgId=1&var-server=${facts['hostname']}&var-datasource=${::site} prometheus/ops"],
        contact_group   => $contact_group,
        query           => "sum(increase(edac_events{hostname=\"${facts['hostname']}\"}[4d]))",
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
        dashboard_links => ["https://grafana.wikimedia.org/dashboard/db/host-overview?orgId=1&var-server=${facts['hostname']}&var-datasource=${::site} prometheus/ops"],
        contact_group   => $contact_group,
        query           => "node_filesystem_avail_bytes{instance=\"${facts['hostname']}:9100\"} > node_filesystem_size_bytes",
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
    if $facts['has_ipmi'] {
        class { 'ipmi::monitor': ensure => $hardware_monitoring }
    }
}
