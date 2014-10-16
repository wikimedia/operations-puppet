# Resource toollabs::hostgroup::collector
#
#
define toollabs::hostgroup::collector( $name = $title )
{

    $hgrpfile  = "/etc/gridengine/local/${name}.hosts";

    file { $dir:
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
    }

    exec { "make-${name}-hosts":
        cwd     => $toollabs::hostgroup:: hgstore,
        command => "(echo group_name @{$name};echo hostlist \$(/bin/egrep -l '^${name}' *)) >'${hgrpfile}'",
    }

    gridengine::hostgroup("@${name}":
        spirce  => $hgrpfile,
        require => Exec["make-${name}-hosts"],
    }

}

