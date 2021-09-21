# == class cloudnfs
#
# This class configures the server as an NFS kernel server (in the cloud realm)
# and sets the general configuration for that service, without
# actually exporting any filesystems
#

class cloudnfs (
    Integer $nfsd_threads = 192,
){

    ensure_packages(['nfs-kernel-server', 'nfs-common', 'lvm2'])

    file { '/etc/idmapd.conf':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/labstore/idmapd.conf',
    }

    # Nethogs is useful to monitor NFS client resource utilization
    package { 'nethogs':
        ensure => present,
    }

    file { '/usr/local/sbin/snapshot-manager':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/labstore/snapshot-manager.py',
    }

    service { 'rpcbind':
        ensure => stopped,
    }

    exec { '/bin/systemctl mask rpcbind.service':
        creates => '/etc/systemd/system/rpcbind.service',
    }

    exec { '/bin/systemctl mask rpcbind.socket':
        creates => '/etc/systemd/system/rpcbind.socket',
    }

    file { '/etc/default/nfs-kernel-server':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        content => template('labstore/nfs-kernel-server.erb'),
    }

    # For some reason, on stretch, this isn't created during install of the nfs
    # server, which causes failures in the nfsdcltrack init
    file { '/var/lib/nfs/nfsdcltrack/':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
    }
}
