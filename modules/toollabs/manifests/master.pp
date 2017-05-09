# Establish the gridengine master role (one per cluster)

class toollabs::master inherits toollabs {

    include ::gridengine::master
    include ::toollabs::infrastructure

    $queue_config = {
        'task'             => {
            hostlist              => '@general',
            seq_no                => 0,
            terminate_method      => '/usr/local/bin/jobkill $job_pid',
        },
        'continuous'       => {
            hostlist              => '@general',
            seq_no                => 1,
            priority              => 10,
            qtype                 => 'BATCH',
            rerun                 => true,
            ckpt_list             => 'continuous',
            terminate_method      => '/usr/local/bin/jobkill $job_pid',
        },
        'webgrid-lighttpd' => {
            hostlist              => '@webgrid',
            seq_no                => 2,
            np_load_avg_threshold => 2.75,
            qtype                 => 'BATCH',
            rerun                 => true,
            slots                 => 256,
            terminate_method      => 'SIGTERM',
            epilog                => '/usr/local/bin/portreleaser',
        },
        'webgrid-generic'  => {
            # FIXME: webgrid-generic is set up with a list of hosts instead of hostgroups.
            # It should just be another hostgroup
            hostlist              => 'NONE',
            seq_no                => 3,
            np_load_avg_threshold => 2.75,
            qtype                 => 'BATCH',
            rerun                 => true,
            slots                 => 256,
            terminate_method      => 'SIGTERM',
            epilog                => '/usr/local/bin/portreleaser',
        },
    }

    $dedicated_queue_config_defaults = {
        'np_load_avg_threshold' => 2.0,
        'priority'              => 10,
        'qtype'                 => 'BATCH',
        'rerun'                 => true,
        'slots'                 => 1000,
        'ckpt_list'             => 'continuous',
    }

    $dedicated_queue_config = {
        'giftbot' => {
            #FIXME: Make this a hostgroup
            hostlist   => 'NONE',
            seq_no     => 5,
            owner_list => 'giftbot',
            user_lists => 'giftbot',
        }
    }

    create_resources(gridengine::queue, $queue_config)
    create_resources(gridengine::queue, $dedicated_queue_config, $dedicated_queue_config_defaults)

    # Set up complexes
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

    # Set up Resource Quota Sets
    gridengine::quota { 'user_slots':
        description => 'Users have 60 user_slots to allocate',
        limit       => 'users {*} hosts * to user_slot=60',
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
