# == Class role::labs::nfs::extras
#
# The role class for the NFS server that makes dumps and other
# datsets avaliable to labs from production - it serves as a readonly
# server to Labs, while being populated from the actual dataset1001 server
# in prod.
#
# The IPs of the servers allowed to populate it ($dump_servers_ips)
# must be set at the node level or via hiera.
#
# This also exports /srv/statistics to allow statistics servers
# a way to rsync public data in from production.
#
class role::labs::nfs::extras($dump_servers_ips) {
    include standard
    include ::labstore
    include ::labstore::monitoring
    include rsync::server

    rsync::server::module { 'pagecounts':
        path        => '/srv/dumps/pagecounts',
        read_only   => 'no',
        hosts_allow => $dump_servers_ips,
    }

    # Allow users to push files from statistics servers here.
    file { '/srv/statistics':
        ensure => 'directory',
    }
    $statistics_servers = hiera('statistics_servers')
    rsync::server::module { 'statistics':
        path        => '/srv/statistics',
        read_only   => 'no',
        hosts_allow => $statistics_servers,
        require     => File['/srv/statistics']
    }

    # This has a flat exports list
    # because it only exports public data unconditionally
    # and read-only
    file { '/etc/exports':
        ensure  => present,
        content => template('nfs/exports.labs_extras.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }
}
