define apt::puppet (
    $version = $puppet_version,
    $packages  = 'puppet puppet-common facter'
    ) {

    if ($version == '2.7') {
        # For precise, we just need to tell apt to use ubuntu provided packages,
        # with an higher priority than the general rule preferring wikimedia
        # packages
        if $::lsbdistcodename == 'precise' {
                apt::pin { "puppet_${title}_${version}.pref":
                    package  => $packages,
                    pin      => 'release o=Ubuntu',
                    priority => 1002
                }
        }
    } else {
        # For trusty, ubuntu packages are puppet 3
        if $::lsbdistcodename == 'trusty' {
            apt::pin { $title:
                package  => $packages,
                pin      => 'release o=Ubuntu',
                priority => 1002
            }
        } elsif $::lsbdistcodename == 'precise' {
            # Ensure the pref file is not there in this case,
            # so that puppet gets updated.
        apt::pin { "puppet_${title}_2.7.pref":
                ensure   => 'absent',
                priority => 0,
                pin      => 'release o=Ubuntu'
            }
        }
    }
}
