define apt::puppet (
    $version = $puppet_version ? {
        undef => '2.7',
        default => $puppet_version,
    },
    $packages  = 'puppet puppet-common facter'
    ) {

    if ($version == '2.7') {
        # For precise, we just need to tell apt to use ubuntu provided packages,
        # with an higher priority than the general rule preferring wikimedia
        # packages
        if $::lsbdistcodename == 'precise' {
                apt::pin {"puppet_${title}_${version}":
                    package  => $packages,
                    pin      => 'release o=Ubuntu',
                    priority => 1002
                }
        }
    } else {
        # For trusty, ubuntu packages are puppet 3
        if $::lsbdistcodename == 'trusty' {
            apt::pin {"$title":
                package  => $packages,
                pin      => 'release o=Ubuntu',
                priority => 1002
            }
        }
    }
}
