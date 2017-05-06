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
}
