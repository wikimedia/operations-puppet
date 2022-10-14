# SPDX-License-Identifier: Apache-2.0
# Class: profile::wmcs::nfs::standalone
#
# Sets up an Openstack instance-based NFS server
#
class profile::wmcs::nfs::standalone(
    Boolean $cinder_attached = lookup('profile::wcms::nfs::standalone::cinder_attached'),
    Boolean $host_scratch    = lookup('profile::wcms::nfs::standalone::host_scratch', {'default_value' => false}),
    Array[String] $volumes   = lookup('profile::wcms::nfs::standalone::volumes'),
) {
    require profile::openstack::eqiad1::observerenv

    motd::script { 'nfs-standalone-banner':
        ensure => present,
        source => 'puppet:///modules/profile/wmcs/nfs/standalone/motd.sh',
    }

    class {'cloudnfs': }

    # The prefix used to create an nfs server has a -count added, so truncating at
    #  the last dash should get us the original host prefix used for the service name
    $host_prefix = regsubst($::hostname, '-[^-]*$', '')
    $nfs_service_name = "${host_prefix}.svc.${::labsproject}.${::wmcs_deployment}.wikimedia.cloud"

    if ($cinder_attached) {
        $nfs_service_ip = ipresolve($nfs_service_name, 4)

        interface::ip { 'nfs-service-ip':
            ensure    => present,
            address   => $nfs_service_ip,
            interface => $facts['interface_primary'],
        }

        $server_running = true
    } else {
        $server_running = false
    }

    sysctl::parameters { 'cloudstore base':
        values   => {
            # Increase TCP max buffer size
            'net.core.rmem_max' => 67108864,
            'net.core.wmem_max' => 67108864,

            # Increase Linux auto-tuning TCP buffer limits
            # Values represent min, default, & max num. of bytes to use.
            'net.ipv4.tcp_rmem' => [ 4096, 87380, 33554432 ],
            'net.ipv4.tcp_wmem' => [ 4096, 65536, 33554432 ],
        },
        priority => 70,
    }

    class {'cloudnfs::fileserver::exports':
        server_vols     => $volumes,
        cinder_attached => $cinder_attached,
        host_scratch    => $host_scratch,
    }

    # state manually managed
    service { 'nfs-server':
        ensure => $server_running;
    }

    file {'/usr/local/sbin/logcleanup':
        source => 'puppet:///modules/cloudnfs/logcleanup.py',
        mode   => '0744',
        owner  => 'root',
        group  => 'root',
    }

    file {'/etc/logcleanup-config.yaml':
        source => 'puppet:///modules/profile/wmcs/nfs/primary/logcleanup-config.yaml',
        mode   => '0644',
        owner  => 'root',
        group  => 'root',
    }
}
