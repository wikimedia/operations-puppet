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
# @param cluster the cluster to ack on
# @param is_critical indicate this host is critical
# @param raid_check indicate if we should check raid
# @param raid_check_interval check interval for raid checks
# @param raid_retry_interval retry interval for raid retries
# @param notifications_enabled indicate if we should send notifications
# @param do_paging if true send pages
# @param nagios_group The nagios group to use for notifications
# @param services A hash of services to monitor on all servers
# @param hosts The hosts to monitor
# @param monitoring_hosts The monitoring hosts used in FW rules
# @param raid_write_cache_policy The raid policy to use for checks
class profile::monitoring (
    Wmflib::Ensure      $hardware_monitoring        = lookup('profile::monitoring::hardware_monitoring'),
    # TODO: make this an array
    String              $contact_group              = lookup('profile::monitoring::contact_group'),
    String              $cluster                    = lookup('profile::monitoring::cluster'),
    Boolean             $is_critical                = lookup('profile::monitoring::is_critical'),
    Boolean             $raid_check                 = lookup('profile::monitoring::raid_check'),
    Integer             $raid_check_interval        = lookup('profile::monitoring::raid_check_interval'),
    Integer             $raid_retry_interval        = lookup('profile::monitoring::raid_retry_interval'),
    Boolean             $notifications_enabled      = lookup('profile::monitoring::notifications_enabled'),
    Boolean             $do_paging                  = lookup('profile::monitoring::do_paging'),
    String              $nagios_group               = lookup('profile::monitoring::nagios_group'),
    Hash                $services                   = lookup('profile::monitoring::services'),
    Hash                $hosts                      = lookup('profile::monitoring::hosts'),
    Array[Stdlib::Host] $monitoring_hosts           = lookup('profile::monitoring::monitoring_hosts'),
    Optional[Enum['WriteThrough', 'WriteBack']] $raid_write_cache_policy = lookup('profile::monitoring::raid_write_cache_policy')
) {
    if $raid_check and $hardware_monitoring == 'present' {
        # RAID checks
        class { 'raid':
            write_cache_policy => $raid_write_cache_policy,
            check_interval     => $raid_check_interval,
            retry_interval     => $raid_retry_interval,
        }
    }

    class { 'monitoring':
        contact_group         => $contact_group,
        nagios_group          => $nagios_group,
        cluster               => $cluster,
        notifications_enabled => $notifications_enabled,
        do_paging             => $do_paging,
        hosts                 => $hosts,
        services              => $services,
    }

    class { 'nrpe':
        allowed_hosts => $monitoring_hosts.join(','),
    }
    # the nrpe class installs monitoring-plugins-* which creates the following directory
    contain nrpe  # lint:ignore:wmf_styleguide

    nrpe::plugin { 'check_sysctl':
        source => 'puppet:///modules/profile/monitoring/check_sysctl',
    }

    nrpe::plugin { 'check_established_connections':
        source => 'puppet:///modules/profile/monitoring/check_established_connections.sh',
    }

    nrpe::plugin { 'check_newest_file_age':
        source => 'puppet:///modules/profile/monitoring/check_newest_file_age.sh',
    }

    if ! $facts['is_virtual'] {
        include profile::prometheus::nic_saturation_exporter
        class { 'prometheus::node_nic_firmware': }
        if $facts['processors']['models'][0] !~ /AMD/ {
            class { 'prometheus::node_intel_microcode': }
        }
    }

    if $facts['has_ipmi'] {
        class { 'ipmi::monitor': ensure => $hardware_monitoring }
    }
}
