# Establish the gridengine master role (one per cluster)

class profile::toolforge::grid::master (
    $etcdir = hiera('profile::toolforge::etcdir'),
    $sge_root = lookup('profile::toolforge::grid::base::sge_root'),
    $geconf = lookup('profile::toolforge::grid::base::geconf'),
    $collectors = lookup('profile::toolforge::grid::base::collectors'),
){
    include profile::openstack::main::clientpackages
    include profile::openstack::main::observerenv
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
        config => 'toollabs/gridengine/queue-webgrid.erb',
    }

    sonofgridengine::collectors::queues { 'webgrid-generic':
        store  => "${collectors}/queues",
        config => 'toollabs/gridengine/queue-webgrid.erb',
    }

    # These things are done on toollabs::master because they
    # need to be done exactly once per project (they live on the
    # shared filesystem), and there can only be exactly one
    # gridmaster in this setup.  They could have been done on
    # any singleton instance.

    file { '/usr/local/bin/dequeugridnodes.sh':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/profile/toolforge/gridscripts/dequeuegridnodes.sh',
    }
    file { '/usr/local/bin/requeugridnodes.sh':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/profile/toolforge/gridscripts/requeuegridnodes.sh',
    }
    file { '/usr/local/bin/runninggridtasks.py':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/profile/toolforge/gridscripts/runninggridtasks.py',
    }
    file { '/usr/local/bin/runninggridjobsmail.py':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/profile/toolforge/gridscripts/runninggridjobsmail.py',
    }

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
}
