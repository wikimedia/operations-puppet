# == class labstore::fileserver
#
# This configures a server for serving NFS filesystems to Labs
# instances.  Applying this classes suffices to make a server
# capable of serving this function, but neither activates nor
# enables it to do so by itself (as this requires manual
# intervention at this time because of the shared storage).
#
# The single class parameter is the interface to monitor for
# alerting purposes.  This should be the interface holding
# the IP address that serves NFS.

class labstore::fileserver($monitor_iface = 'eth0') {

    include ::labstore

    file { '/etc/init/manage-nfs-volumes.conf':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/labstore/manage-nfs-volumes.conf',
    }

    file { '/usr/local/sbin/start-nfs':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0550',
        source  => 'puppet:///modules/labstore/start-nfs',
    }

    file { '/usr/local/sbin/set-stripe-cache':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => 'puppet:///modules/labstore/set-stripe-cache',
    }

    # This is done unconditionally to all the md devices at
    # interval to guard against (a) puppet not applying for
    # any reason, and (b) the fact that the set of started
    # md devices on a labstore* is ultimately variable and
    # dynamic depending on its current role.
    #
    cron { 'set-stripe-caches':
        command => '/usr/local/sbin/set-stripe-cache 4096',
        user    => 'root',
        minute  => '*/5',
        require => File['/usr/local/sbin/set-stripe-cache'],
    }

    $sudo_privs = [ 'ALL = NOPASSWD: /bin/mkdir -p /srv/*',
            'ALL = NOPASSWD: /bin/rmdir /srv/*',
            'ALL = NOPASSWD: /usr/local/sbin/sync-exports' ]
    sudo::user { [ 'nfsmanager' ]: privileges => $sudo_privs, require => User['nfsmanager'] }

    group { 'nfsmanager':
        ensure => present,
        name   => 'nfsmanager',
        system => true,
    }

    user { 'nfsmanager':
        home       => '/var/lib/nfsmanager',
        shell      => '/bin/bash',
        managehome => true,
        system     => true,
    }

    file { '/etc/exports.d':
        ensure => directory,
        owner  => 'root',
        group  => 'nfsmanager',
        mode   => '2775',
    }

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
        warning     => '25', # Based off looking at history of metric
        critical    => '35',
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

}
