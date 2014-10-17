# Resource toollabs::hostgroup::collector
#
#
define toollabs::hostgroup::collector( $hgname = $title )
{

    $hgrpfile  = "/etc/gridengine/local/${hgname}.hosts"

    exec { "make-${hgname}-hosts":
        command => "/etc/gridengine/local/bin/gethgrp ${hgname} ${hgrpfile} ${toollabs::hostgroup::hgstore}",
        require => File['/etc/gridengine/local/bin/gethgrp'],
    }

    gridengine::hostgroup { "@${hgname}":
        source  => $hgrpfile,
        require => Exec["make-${hgname}-hosts"],
    }

}

