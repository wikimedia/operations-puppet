# = Class: labstore::monitoring
#
# Generic monitoring for all labstore NFS servers
# 
# == Parameters
#
# [*monitor_iface*]
#   Name of interface to monitor for network saturation.
#   This should be the interface holding the IP address
#   that serves NFS
class labstore::monitoring(
    $monitor_iface = 'eth0',
) {
    monitoring::graphite_threshold { 'network_out_saturated':
        description => 'Outgoing network saturation',
        metric      => "servers.${::hostname}.network.${monitor_iface}.tx_byte",
        from        => '30min',
        warning     => '75000000',  # roughly 600Mbps / 1Gbps
        critical    => '100000000', # roughly 800Mbps / 1Gbps
        percentage  => '10',        # smooth over peaks
    }

    monitoring::graphite_threshold { 'network_in_saturated':
        description => 'Incoming network saturation',
        metric      => "servers.${::hostname}.network.${monitor_iface}.rx_byte",
        from        => '30min',
        warning     => '75000000',  # roughly 600Mbps / 1Gbps
        critical    => '100000000', # roughly 800Mbps / 1Gbps
        percentage  => '10',        # smooth over peaks
    }

    monitoring::graphite_threshold { 'high_iowait_stalling':
        description => 'Persistent high iowait',
        metric      => "servers.${::hostname}.cpu.total.iowait",
        from        => '10min',
        warning     => '40', # Based off looking at history of metric
        critical    => '60',
        percentage  => '50', # Ignore small spikes
    }

    # Monitor for high load consistently, is a 'catchall'
    monitoring::graphite_threshold { 'high_load':
        description => 'High load average',
        metric      => "servers.${::hostname}.loadavg.01",
        from        => '10min',
        warning     => '16',
        critical    => '24',
        percentage  => '50', # Don't freak out on spikes
    }

    # Monitor that getent passwd over LDAP resolves in reasonable time
    # (this being the mechanism that NFS uses to fetch groups)
    nrpe::monitor_service { 'getent_check':
        nrpe_command => '/usr/local/bin/getent_check',
        description  => 'Getent speed check',
        require      => File['/usr/local/bin/getent_check'],
    }

    file { '/usr/local/bin/getent_check':
        ensure => present,
        source => 'puppet:///modules/labstore/getent_check',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }
}
