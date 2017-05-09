# gridengine/master.pp

class gridengine::master {

    include ::gridengine

    package { ['gridengine-master', 'gridengine-client']:
        ensure  => latest,
        require => Package['gridengine-common'],
    }

    # berkleydb utils for doing db recovery and other operations
    package {'db-util':
        ensure => latest,
    }

    $etcdir = '/var/lib/gridengine/etc'

    gridengine::resourcedir { 'exechosts': }
    gridengine::resourcedir { 'submithosts': }
    gridengine::resourcedir { 'adminhosts': }

    file { "${etcdir}/config":
        ensure  => directory,
        force   => true,
        owner   => 'sgeadmin',
        group   => 'sgeadmin',
        mode    => '0775',
        recurse => true,
        purge   => true,
    }

    # Set up global grid config
    file { "${etcdir}/config/global":
        ensure => file,
        owner  => 'sgeadmin',
        group  => 'sgeadmin',
        mode   => '0664',
        source => 'puppet:///modules/gridengine/global.conf',
    }

    # Set up grid scheduler config
    file { "${etcdir}/config/grid-scheduler-conf":
        ensure => file,
        owner  => 'sgeadmin',
        group  => 'sgeadmin',
        mode   => '0664',
        source => 'puppet:///modules/gridengine/grid-scheduler.conf',
    }

    # Set up config directory for grid compononents
    $config_dirs_defaults = {
        ensure => directory,
        owner  => 'sgeadmin',
        group  => 'sgeadmin',
        mode   => '0775',
    }

    $config_dirs = {
        'hostgroups'  => { path => "${etcdir}/hostgroups",},
        'queues'      => { path => "${etcdir}/queues", },
        'quotas'      => { path => "${etcdir}/quotas", },
        'checkpoints' => { path => "${etcdir}/checkpoints", },
    }

    create_resources(file, $config_dirs, $config_dirs_defaults)

    service { 'gridengine-master':
        ensure    => running,
        enable    => true,
        hasstatus => false,
        pattern   => 'sge_qmaster',
        require   => Package['gridengine-master'],
    }
}
