# Resource toollabs::hostgroup::collector
#
#
define toollabs::hostgroup::collector( $name = $title )
{

    file { $dir:
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
    }

    exec { "make-${name}-hosts":
        cwd     => $toollabs::hostgroup::hgstore,
        command => "(echo group_name @{$name};echo hostlist \$(/bin/egrep -l '^${name}' *)) >'/etc/gridengine/local/${name}.hosts'",
    }

    gridengine::hostgroup { "@${name}":
        source  => "/etc/gridengine/local/${name}.hosts",
        require => Exec["make-${name}-hosts"],
    }

}

