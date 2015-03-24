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

    $gangla_aggregator = true

    include standard
    include rsync::server

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
class role::labs::nfs::fileserver {

    $gangla_aggregator = true

    include standard

    # eqiad still uses LDAP for now
    # T87870
    if $::site == 'eqiad' {
        class { 'ldap::role::client::labs':
            ldapincludes => ['openldap', 'nss', 'utils'],
        }
    } else {
        include admin
    }

    include openstack::project-nfs-storage-service
    include openstack::replica_management_service

    monitoring::graphite_threshold { 'network_out_saturated':
        description => 'Outgoing network saturation',
        metric      => "servers.${::hostname}.network.bond0.tx_byte.value",
        from        => '30min',
        warning     => '75000000',  # roughly 600Mbps / 1Gbps
        critical    => '100000000', # roughly 800Mbps / 1Gbps
        percentage  => '10',        # smooth over peaks
    }

    monitoring::graphite_threshold { 'network_in_saturated':
        description => 'Incoming network saturation',
        metric      => "servers.${::hostname}.network.bond0.rx_byte.value",
        from        => '30min',
        warning     => '75000000',  # roughly 600Mbps / 1Gbps
        critical    => '100000000', # roughly 800Mbps / 1Gbps
        percentage  => '10',        # smooth over peaks
    }

}

