# Class: role::labs::nfs::dumps
#
# The role class for the NFS server that makes dumps avaliable
# to labs from production - it serves as a readonly server to Labs,
# while being populated from the actual dumps server in prod.
#
# The IPs of the servers allowed to populate it ($dump_servers_ips)
# must be set at the node level or via hiera
#
class role::labs::nfs::dumps($dump_servers_ips) {

    include standard

    package { 'nfs-kernel-server':
        ensure => present,
    }

    file { '/etc/exports':
        ensure  => present,
        content => template('nfs/exports.dumps.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

}
