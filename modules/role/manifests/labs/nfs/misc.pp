# NFS misc server:
# - dumps
# - statistics data shuffle
# - scratch
#
# The IPs of the servers allowed to populate dumps ($dump_servers_ips)
# must be set at the node level or via hiera.
#


class role::labs::nfs::misc($dump_servers_ips) {
    include standard
    include labstore
    include labstore::monitoring
    include rsync::server

    rsync::server::module { 'pagecounts':
        path        => '/srv/dumps/pagecounts',
        read_only   => 'no',
        hosts_allow => $dump_servers_ips,
    }

    rsync::server::module { 'dumps':
        path        => '/srv/dumps',
        read_only   => 'no',
        hosts_allow => $dump_servers_ips,
    }

    # Allow users to push files from statistics servers here.
    file { '/srv/statistics':
        ensure => 'directory',
    }

    # This also exports /srv/statistics to allow statistics servers
    # a way to rsync public data in from production.
    $statistics_servers = hiera('statistics_servers')
    rsync::server::module { 'statistics':
        path        => '/srv/statistics',
        read_only   => 'no',
        hosts_allow => $statistics_servers,
        require     => File['/srv/statistics']
    }

    file { '/srv/scratch':
        ensure => 'directory',
    }

    # This has a flat exports list
    # because it only exports public data
    # unconditionally and ro or
    # as available to all
    file { '/etc/exports':
        ensure  => present,
        content => template('labstore/exports.labs_extras.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }
}
