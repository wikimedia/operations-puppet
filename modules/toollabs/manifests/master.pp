# Establish the gridengine master role (one per cluster)

class toollabs::master inherits toollabs {

    include ::gridengine::master
    include ::toollabs::infrastructure
    include ::toollabs::queue::continuous
    include ::toollabs::queue::task

    gridengine_resource { 'h_vmem':
        ensure      => present,
        requestable => 'FORCED',
        consumable  => 'YES',
        require     => Service['gridengine-master'],
    }

    gridengine_resource { 'release':
        ensure      => present,
        shortcut    => 'rel',
        type        => 'CSTRING',
        relop       => '==',
        requestable => 'YES',
        consumable  => 'NO',
        default     => 'NONE',
        urgency     => '0',
        require     => Service['gridengine-master'],
    }

    gridengine_resource { 'user_slot':
        ensure      => present,
        shortcut    => 'u',
        type        => 'INT',
        relop       => '<=',
        requestable => 'YES',
        consumable  => 'YES',
        default     => '0',
        urgency     => '0',
        require     => Service['gridengine-master'],
    }

    file { "${toollabs::collectors}/hostgroups":
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { "${toollabs::collectors}/queues":
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    gridengine::collectors::hostgroups { '@general':
        store => "${toollabs::collectors}/hostgroups",
    }

    gridengine::collectors::queues { 'webgrid-lighttpd':
        store  => "${toollabs::collectors}/queues",
        config => 'toollabs/gridengine/queue-webgrid.erb',
    }

    gridengine::collectors::queues { 'webgrid-generic':
        store  => "${toollabs::collectors}/queues",
        config => 'toollabs/gridengine/queue-webgrid.erb',
    }

    #
    # These things are done on toollabs::master because they
    # need to be done exactly once per project (they live on the
    # shared filesystem), and there can only be exactly one
    # gridmaster in this setup.  They could have been done on
    # any singleton instance.
    #

    # Make sure that old-style fqdn for nodes are still understood
    # in this new-style fqnd environment by making aliases for the
    # nodes that existed before the change:
    file { '/var/lib/gridengine/default/common/host_aliases':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/toollabs/host_aliases',
        require => File['/var/lib/gridengine'],
    }

    file { '/usr/local/bin/dequeugridnodes.sh':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/toollabs/gridscripts/dequeuegridnodes.sh',
    }
    file { '/usr/local/bin/requeugridnodes.sh':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/toollabs/gridscripts/requeuegridnodes.sh',
    }
    file { '/usr/local/bin/runninggridtasks.py':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/toollabs/gridscripts/runninggridtasks.py',
    }
    file { '/usr/local/bin/runninggridjobsmail.py':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/toollabs/gridscripts/runninggridjobsmail.py',
    }

    file { "${toollabs::geconf}/spool":
        ensure  => directory,
        owner   => 'sgeadmin',
        group   => 'sgeadmin',
        require => File[$toollabs::geconf],
    }

    file { '/var/spool/gridengine':
        ensure  => link,
        target  => "${toollabs::geconf}/spool",
        force   => true,
        require => File["${toollabs::geconf}/spool"],
    }

    file { '/usr/local/sbin/exec-manage':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0655',
        source => 'puppet:///modules/toollabs/exec-manage',
    }
}
