# Class: role::labs::nfs::dumps
#
# The role class for the NFS server that makes dumps avaliable
# to labs from production - it serves as a readonly server to Labs,
# while being populated from the actual dumps server in prod.
#
# The IPs of the servers allowed to populate it ($dump_servers_ips)
# must be set at the node level or via hiera.
#
class role::labs::nfs::dumps($dump_servers_ips) {
    include standard
    include ::labstore
    include rsync::server

    # The dumps server has a simple, flat exports list
    # because it only exports public data unconditionally
    # and read-only

    file { '/etc/exports':
        ensure  => present,
        content => template('nfs/exports.dumps.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    rsync::server::module {
        'pagecounts':
            path        => '/srv/dumps/pagecounts',
            read_only   => 'no',
            hosts_allow => $dump_servers_ips,
    }

}

# Class: role::labs::nfs::fileserver
#
# The role class for the NFS servers that provide general filesystem
# services to Labs.
#
class role::labs::nfs::fileserver($monitor = 'eth0') {
    include standard

    class { 'include ::labstore::fileserver':
        monitor_iface => $monitor,
    }
}

