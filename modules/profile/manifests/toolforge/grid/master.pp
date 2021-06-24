# Establish the gridengine master role (one per cluster)

class profile::toolforge::grid::master (
    Stdlib::Unixpath $etcdir     = lookup('profile::toolforge::etcdir'),
    Stdlib::Unixpath $sge_root   = lookup('profile::toolforge::grid::base::sge_root'),
    Stdlib::Unixpath $geconf     = lookup('profile::toolforge::grid::base::geconf'),
    Stdlib::Unixpath $collectors = lookup('profile::toolforge::grid::base::collectors'),
){
    include profile::openstack::eqiad1::clientpackages::vms
    include profile::openstack::eqiad1::observerenv
    include profile::toolforge::infrastructure

    $hostlist = '@general'

    class { '::prometheus::node_sge': }

    sonofgridengine::queue { 'task':
        config => 'profile/toolforge/grid/queue-task.erb',
    }

    sonofgridengine::queue { 'continuous':
        config => 'profile/toolforge/grid/queue-continuous.erb',
    }

    sonofgridengine::checkpoint { 'continuousckpt':
        config => 'profile/toolforge/grid/ckpt-continuous.erb',
    }

    file { "${collectors}/hostgroups":
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { "${collectors}/queues":
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    sonofgridengine::collectors::hostgroups { '@general':
        store => "${collectors}/hostgroups",
    }

    sonofgridengine::collectors::queues { 'webgrid-lighttpd':
        store  => "${collectors}/queues",
        config => 'profile/toolforge/grid/queue-webgrid.erb',
    }

    sonofgridengine::collectors::queues { 'webgrid-generic':
        store  => "${collectors}/queues",
        config => 'profile/toolforge/grid/queue-webgrid.erb',
    }

    # These things are done on the grid master because they
    # need to be done exactly once per project (they live on the
    # shared filesystem), and there can only be exactly one
    # gridmaster in this setup.  They could have been done on
    # any singleton instance.

    file { "${geconf}/spool":
        ensure  => directory,
        owner   => 'sgeadmin',
        group   => 'sgeadmin',
        require => File[$geconf],
    }

    file { '/var/spool/gridengine':
        ensure  => link,
        target  => "${geconf}/spool",
        force   => true,
        require => File["${geconf}/spool"],
    }

    file { '/var/spool/gridengine/qmaster':
        ensure  => directory,
        owner   => 'sgeadmin',
        group   => 'sgeadmin',
        require => File[$geconf],
    }

    file { '/var/spool/gridengine/spooldb':
        ensure  => directory,
        owner   => 'sgeadmin',
        group   => 'sgeadmin',
        require => File[$geconf],
    }

    class { '::sonofgridengine::master':
        etcdir  => $etcdir,
    }

    file { "${geconf}/default/common/shadow_masters":
        ensure => present,
        owner  => 'sgeadmin',
        group  => 'sgeadmin',
        mode   => '0555',
    } -> file_line { 'shadow_masters':
        ensure => present,
        line   => $facts['fqdn'],
        path   => "${geconf}/default/common/shadow_masters",
    }

    file { "${etcdir}/config/global":
        ensure => file,
        owner  => 'sgeadmin',
        group  => 'sgeadmin',
        mode   => '0664',
        source => 'puppet:///modules/profile/toolforge/grid-global-config',
    }

    file { "${etcdir}/config/scheduler":
        ensure => file,
        owner  => 'sgeadmin',
        group  => 'sgeadmin',
        mode   => '0664',
        source => 'puppet:///modules/profile/toolforge/grid-scheduler-config',
    }

    file { '/usr/local/sbin/exec-manage':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0655',
        source => 'puppet:///modules/profile/toolforge/exec-manage',
    }

    exec { 'update-global-config':
        command     => "/usr/bin/qconf -Mconf ${etcdir}/config/global",
        subscribe   => File["${etcdir}/config/global"],
        refreshonly => true,
    }

    exec { 'update-scheduler-config':
        command     => "/usr/bin/qconf -Msconf ${etcdir}/config/scheduler",
        subscribe   => File["${etcdir}/config/scheduler"],
        refreshonly => true,
    }

    class { 'sonofgridengine::logrotate':
        ensure   => 'present',
        sge_root => $sge_root,
    }

    # The disable_tools script only needs ldap creds on
    #  the NFS host.
    $novaadmin_bind_dn='<unavailable here>'
    $novaadmin_bind_pass='<unavailable here>'
    file { '/etc/disable_tools.conf':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0500',
        content => template('profile/toolforge/disable_tools.conf.erb'),
    }
}
