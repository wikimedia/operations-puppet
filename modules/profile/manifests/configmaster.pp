class profile::configmaster(
    $conftool_prefix = hiera('conftool_prefix'),
    $datacenters = hiera('datacenters'),
) {
    system::role { 'config-master': description => 'Dynamic configuration HTTP host' }

    $vhostnames = [
        'config-master.eqiad.wmnet',
        'config-master.codfw.wmnet',
        'config-master.esams.wmnet',
        'config-master.ulsfo.wmnet',
        'config-master.wikimedia.org',
    ]

    $root_dir = '/srv/config-master'

    file { $root_dir:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    # ensure the prefix is passed down
    Pybal::Conf_file {
        prefix => $conftool_prefix,
    }

    # Write pybal pools
    class { '::pybal::web':
        ensure      => present,
        root_dir    => $root_dir,
        datacenters => $datacenters,
    }

    apache::site { 'config-master':
        ensure   => present,
        priority => 50,
        content  => template('profile/configmaster/config-master.conf.erb'),
        notify   => Service['apache2'],
        require  => File[$root_dir],
    }

    ferm::service { 'pybal_conf-http':
        proto  => 'tcp',
        port   => 80,
        srange => '$PRODUCTION_NETWORKS',
    }

}
