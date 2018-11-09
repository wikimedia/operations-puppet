# Establish the gridengine master role (one per cluster)

class profile::toolforge::grid::master (
    $etcdir = hiera('profile::toolforge::etcdir'),
){
    include profile::toolforge::infrastructure

    $hostlist = '@general'

    sonofgridengine::queue { 'task':
        config => 'profile/toolforge/grid/queue-task.erb',
    }

    sonofgridengine::queue { 'continuous':
        config => 'profile/toolforge/grid/queue-continuous.erb',
    }

    sonofgridengine::checkpoint { 'continuousckpt':
        config => 'profile/toolforge/grid/ckpt-continuous.erb',
    }

    # For when we deploy the web nodes

    # sonofgridengine::queue { 'webgrid-lighttpd':
    #     config => 'profile/toolforge/grid/queue-webgrid.erb',
    # }

    # sonofgridengine::queue { 'webgrid-generic':
    #     config => 'profile/toolforge/grid/queue-webgrid.erb',
    # }

    class { '::sonofgridengine::master':
        etcdir  => $etcdir,
    }

    file { "${profile::toolforge::grid::base::collectors}/hostgroups":
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { "${profile::toolforge::grid::base::collectors}/queues":
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    sonofgridengine::collectors::hostgroups { '@general':
        store => "${profile::toolforge::grid::base::collectors}/hostgroups",
    }

    sonofgridengine::collectors::queues { 'webgrid-lighttpd':
        store  => "${profile::toolforge::grid::base::collectors}/queues",
        config => 'toollabs/gridengine/queue-webgrid.erb',
    }

    sonofgridengine::collectors::queues { 'webgrid-generic':
        store  => "${profile::toolforge::grid::base::collectors}/queues",
        config => 'toollabs/gridengine/queue-webgrid.erb',
    }


    # These things are done on toollabs::master because they
    # need to be done exactly once per project (they live on the
    # shared filesystem), and there can only be exactly one
    # gridmaster in this setup.  They could have been done on
    # any singleton instance.


    # Make sure that old-style fqdn for nodes are still understood
    # in this new-style fqdn environment by making aliases for the
    # nodes that existed before the change:
    # UPDATE: commented out because all of the aliases are for old hosts.
    # file { '/var/lib/gridengine/default/common/host_aliases':
    #     ensure  => file,
    #     owner   => 'root',
    #     group   => 'root',
    #     mode    => '0444',
    #     source  => 'puppet:///modules/profile/toolforge/host_aliases',
    #     require => File['/var/lib/gridengine'],
    # }


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

    file { "${profile::toolforge::grid::base::geconf}/spool":
        ensure  => directory,
        owner   => 'sgeadmin',
        group   => 'sgeadmin',
        require => File[$toolforge::geconf],
    }

    file { '/var/spool/gridengine':
        ensure  => link,
        target  => "${profile::toolforge::grid::base::geconf}/spool",
        force   => true,
        require => File["${profile::toolforge::grid::base::geconf}/spool"],
    }

    file { '/var/spool/gridengine/qmaster':
        ensure  => directory,
        owner   => 'sgeadmin',
        group   => 'sgeadmin',
        require => File[$profile::toolforge::grid::base::geconf],
    }

    file { '/var/spool/gridengine/spooldb':
        ensure  => directory,
        owner   => 'sgeadmin',
        group   => 'sgeadmin',
        require => File[$profile::toolforge::grid::base::geconf],
    }

    # This must only run on install
    exec { 'initialize-grid-database':
        command  => "/usr/share/gridengine/scripts/init_cluster ${profile::toolforge::grid::base::sge_root} default /var/spool/gridengine/spooldb sgeadmin",
        require  => File['/var/spool/gridengine', "${profile::toolforge::grid::base::geconf}/spool"],
        creates  => '/var/spool/gridengine/spooldb/sge',
        user     => 'sgeadmin',
        provider => 'shell',
    }
}
