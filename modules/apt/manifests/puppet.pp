# FIXME: remove this class and all of its callsites after a reasonable time has passed -2014-12-09
define apt::puppet (
    $packages  = 'puppet puppet-common facter'
    ) {

    apt::pin { $title:
        ensure   => 'absent',
        package  => $packages,
        pin      => 'release o=Ubuntu',
        priority => 1002
    }
    apt::pin { "puppet_${title}_2.7.pref":
        ensure   => 'absent',
        priority => 0,
        pin      => 'release o=Ubuntu'
    }
}
