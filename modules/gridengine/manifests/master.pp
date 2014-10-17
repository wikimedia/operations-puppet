# gridengine/master.pp

class gridengine::master
{
    class { 'gridengine':
        gridmaster => $fqdn,
    }

    package { 'gridengine-master':
        ensure  => latest,
        require => Package['gridengine-common'],
    }

    $etcdir = '/etc/gridengine/local'

    file { $etcdir:
        ensure  => directory,
        require => Package['gridengine-master'],
        force   => true,
        owner   => 'sgeadmin',
        group   => 'sgeadmin',
        mode    => '0775',
        recurse => false,
        purge   => true,
    }

    file { "$etcdir/.tracker":
        ensure  => directory,
        force   => true,
        owner   => 'sgeadmin',
        group   => 'sgeadmin',
        mode    => '0775',
        recurse => false,
        purge   => true,
    }

    file { "$etcdir/bin":
        ensure       => directory,
        force        => true,
        owner        => 'root',
        group        => 'root',
        mode         => '0755',
        recurse      => true,
        purge        => true,
        sourceselect => all,
        source       => [ 'puppet:///modules/gridengine/mergeconf',
                          'puppet:///modules/gridengine/trackpurge',
                          'puppet:///modules/gridengine/runpurge' ],
    }

    gridengine::resourcedir { 'queues': }
    gridengine::resourcedir { 'hostgroups': }
    gridengine::resourcedir { 'quotas': }
    gridengine::resourcedir { 'checkpoints': }
    gridengine::resourcedir { 'exechosts':   local => false }
    gridengine::resourcedir { 'submithosts': local => false }

    file { "$etcdir/complex":
        ensure  => directory,
        force   => true,
        owner   => 'sgeadmin',
        group   => 'sgeadmin',
        mode    => '0775',
        recurse => true,
        purge   => true,
    }

    file { "$etcdir/complex/99-default":
        ensure  => file,
        owner   => 'sgeadmin',
        group   => 'sgeadmin',
        mode    => '0664',
        source  => 'puppet:///modules/gridengine/99-default',
    }

    exec { "update-complex-conf":
        onlyif  => "$etcdir/bin/mergeconf $etcdir/complex.conf $etcdir/complex/*",
        command => "/bin/echo /usr/bin/qconf -Mc $etcdir/complex.conf'",
        require => File[ "$etcdir/bin", "$etcdir/complex/99-default" ],
    }

    file { "$etcdir/config":
        ensure  => directory,
        force   => true,
        owner   => 'sgeadmin',
        group   => 'sgeadmin',
        mode    => '0775',
        recurse => true,
        purge   => true,
    }

    file { "$etcdir/config/99-default":
        ensure  => file,
        owner   => 'sgeadmin',
        group   => 'sgeadmin',
        mode    => '0664',
        source  => 'puppet:///modules/gridengine/config-99-default',
    }

    exec { "update-config-conf":
        onlyif  => "$etcdir/bin/mergeconf $etcdir/config.conf $etcdir/config/*",
        command => "/bin/echo /usr/bin/qconf -Mconf $etcdir/config.conf",
        require => File[ "$etcdir/bin", "$etcdir/complex/99-default" ],
    }

}

