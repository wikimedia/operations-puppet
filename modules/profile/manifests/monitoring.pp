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
class profile::monitoring(
    Wmflib::Ensure      $hardware_monitoring        = lookup('profile::monitoring::hardware_monitoring'),
    # TODO: make this an array
    String              $contact_group              = lookup('profile::monitoring::contact_group'),
    String              $mgmt_contact_group         = lookup('profile::monitoring::mgmt_contact_group'),
    String              $cluster                    = lookup('profile::monitoring::cluster'),
    Boolean             $is_critical                = lookup('profile::monitoring::is_critical'),
    Boolean             $monitor_systemd            = lookup('profile::monitoring::monitor_systemd'),
    String              $nrpe_check_disk_options    = lookup('profile::monitoring::nrpe_check_disk_options'),
    Boolean             $nrpe_check_disk_critical   = lookup('profile::monitoring::nrpe_check_disk_critical'),
    Boolean             $raid_check                 = lookup('profile::monitoring::raid_check'),
    Integer             $raid_check_interval        = lookup('profile::monitoring::raid_check_interval'),
    Integer             $raid_retry_interval        = lookup('profile::monitoring::raid_retry_interval'),
    Boolean             $notifications_enabled      = lookup('profile::monitoring::notifications_enabled'),
    Boolean             $do_paging                  = lookup('profile::monitoring::do_paging'),
    String              $nagios_group               = lookup('profile::monitoring::nagios_group'),
    Hash                $mgmt_parents               = lookup('profile::monitoring::mgmt_parents'),
    Hash                $services                   = lookup('profile::monitoring::services'),
    Hash                $hosts                      = lookup('profile::monitoring::hosts'),
    Array[Stdlib::Host] $monitoring_hosts           = lookup('profile::monitoring::monitoring_hosts'),
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

    class { 'monitoring':
        contact_group         => $contact_group,
        mgmt_contact_group    => $mgmt_contact_group,
        nagios_group          => $nagios_group,
        cluster               => $cluster,
        notifications_enabled => $notifications_enabled,
        do_paging             => $do_paging,
        mgmt_parents          => $mgmt_parents,
        hosts                 => $hosts,
        services              => $services,
    }


    sudo::user { 'nagios_puppetrun':
        user       => 'nagios',
        privileges => ['ALL = NOPASSWD: /usr/local/lib/nagios/plugins/check_puppetrun'],
    }

    class { 'nrpe':
        allowed_hosts => $monitoring_hosts.join(','),
    }
    # the nrpe class installs monitoring-plugins-* which creates the following directory
    contain nrpe  # lint:ignore:wmf_styleguide

    nrpe::plugin { 'check_puppetrun':
        source => 'puppet:///modules/profile/monitoring/check_puppetrun.rb',
    }

    nrpe::plugin { 'check_eth':
        content => template('profile/monitoring/check_eth.erb'),
    }

    nrpe::plugin { 'check_sysctl':
        source => 'puppet:///modules/profile/monitoring/check_sysctl',
    }

    nrpe::plugin { 'check_established_connections':
        source => 'puppet:///modules/profile/monitoring/check_established_connections.sh',
    }

    nrpe::plugin { 'check_fresh_files_in_dir':
        source => 'puppet:///modules/profile/monitoring/check_fresh_files_in_dir.py'
    }

    file { [
        '/usr/lib/nagios/plugins/check_sysctl',
        '/usr/lib/nagios/plugins/check_established_connections',
        '/usr/lib/nagios/plugins/check-fresh-files-in-dir.py',
    ]:
        ensure => absent,
    }

    nrpe::monitor_service { 'disk_space':
        description     => 'Disk space',
        critical        => $nrpe_check_disk_critical,
        nrpe_command    => "/usr/lib/nagios/plugins/check_disk ${nrpe_check_disk_options}",
        notes_url       => 'https://wikitech.wikimedia.org/wiki/Monitoring/Disk_space',
        dashboard_links => ["https://grafana.wikimedia.org/d/000000377/host-overview?var-server=${facts['hostname']}&var-datasource=${::site} prometheus/ops"],
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

    nrpe::plugin { 'check_systemd_state':
        ensure => $ensure_monitor_systemd,
        source => 'puppet:///modules/profile/monitoring/check_systemd_state.py',
    }

    nrpe::monitor_service { 'check_systemd_state':
        ensure       => $ensure_monitor_systemd,
        description  => 'Check systemd state',
        nrpe_command => '/usr/local/lib/nagios/plugins/check_systemd_state',
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Monitoring/check_systemd_state',
    }

    if $facts['productname'] == 'PowerEdge R320' {

        nrpe::plugin { 'check_cpufreq':
            source => 'puppet:///modules/profile/monitoring/check_cpufreq',
        }

        nrpe::monitor_service { 'check_cpufreq':
            description  => 'CPU frequency',
            nrpe_command => '/usr/local/lib/nagios/plugins/check_cpufreq 600',
            notes_url    => 'https://wikitech.wikimedia.org/wiki/Monitoring/check_cpufreq',
        }
    }


    if ! $facts['is_virtual'] {
        include profile::prometheus::nic_saturation_exporter
        class { 'prometheus::node_nic_firmware': }
        if $::processor0 !~ /AMD/ {
            class { 'prometheus::node_intel_microcode': }
        }
    }

    # Did an host register an increase in correctable errors over the last 4d? Might indicate faulty
    # memory
    monitoring::check_prometheus { 'edac_correctable_errors':
        ensure          => $hardware_monitoring,
        description     => 'Memory correctable errors (EDAC)',
        dashboard_links => ["https://grafana.wikimedia.org/d/000000377/host-overview?orgId=1&var-server=${facts['hostname']}&var-datasource=${::site} prometheus/ops"],
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
        dashboard_links => ["https://grafana.wikimedia.org/d/000000377/host-overview?orgId=1&var-server=${facts['hostname']}&var-datasource=${::site} prometheus/ops"],
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
    # This check is only relavant on Stretch and older, remove after Stretch is gone:
    # https://phabricator.wikimedia.org/T302687
    if debian::codename::le('stretch') {
        monitoring::check_prometheus { 'filesystem_avail_bigger_than_size':
            description     => 'Filesystem available is greater than filesystem size',
            dashboard_links => ["https://grafana.wikimedia.org/d/000000377/host-overview?orgId=1&var-server=${facts['hostname']}&var-datasource=${::site} prometheus/ops"],
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
    }
    if $facts['has_ipmi'] {
        class { 'ipmi::monitor': ensure => $hardware_monitoring }
    }
    # This is responsible for ~75%+ of all recdns queries...
    # https://phabricator.wikimedia.org/T239862
    host { 'statsd.eqiad.wmnet':
        ip           => '10.64.16.149', # graphite1004
        host_aliases => 'statsd',
    }
}
