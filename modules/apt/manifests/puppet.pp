define apt::puppet (
    $packages  = 'puppet puppet-common facter'
    ) {

    # For trusty, ubuntu packages are puppet 3
    if $::lsbdistcodename == 'trusty' {
        apt::pin { $title:
            package  => $packages,
            pin      => 'release o=Ubuntu',
            priority => 1002
        }
    }
    elsif $::lsbdistcodename == 'precise' {
        # Ensure the pref file is not there in this case,
        # so that puppet gets updated.
        apt::pin { "puppet_${title}_2.7.pref":
            ensure   => 'absent',
            priority => 0,
            pin      => 'release o=Ubuntu'
        }
    }
}
