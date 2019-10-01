class profile::configmaster(
    $conftool_prefix = hiera('conftool_prefix'),
) {
    include ::lvs::configuration
    $vhostnames = [
        'config-master.eqiad.wmnet',
        'config-master.codfw.wmnet',
        'config-master.esams.wmnet',
        'config-master.ulsfo.wmnet',
        'config-master.eqsin.wmnet',
        'config-master.wikimedia.org',
    ]

    $root_dir = '/srv/config-master'

    file { $root_dir:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    # The contents of these files are managed by puppet-merge, but user
    # gitpuppet can't/shouldn't be able to create files under $root_dir.
    # So puppet makes sure the file at least exists, and then puppet-merge
    # can write.
    file { "${root_dir}/puppet-sha1.txt":
        ensure => present,
        owner  => 'gitpuppet',
        group  => 'gitpuppet',
        mode   => '0644',
    }

    file { "${root_dir}/labsprivate-sha1.txt":
        ensure => present,
        owner  => 'gitpuppet',
        group  => 'gitpuppet',
        mode   => '0644',
    }

    # Write pybal pools
    class { '::pybal::web':
        ensure   => present,
        root_dir => $root_dir,
        services => $::lvs::configuration::lvs_services
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
