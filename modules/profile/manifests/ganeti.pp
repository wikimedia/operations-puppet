class profile::ganeti {

    # Ganeti hosts have KSM enabled. So get stats about it
    diamond::collector { 'KSM': }

    # Ganeti needs intracluster SSH root access
    ssh::userkey { 'root-ganeti':
        ensure => present,
        user   => 'root',
        skey   => 'ganeti',
        source => 'puppet:///modules/role/ganeti/id_dsa.pub',
    }

    # And the private key
    file { '/root/.ssh/id_dsa':
        ensure    => present,
        owner     => 'root',
        group     => 'root',
        mode      => '0400',
        content   => secret('ganeti/id_dsa'),
        show_diff => false,
    }
    # This is here for completeness
    file { '/root/.ssh/id_dsa.pub':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0400',
        source => 'puppet:///modules/role/ganeti/id_dsa.pub',
    }

    class { '::ganeti': }
}
