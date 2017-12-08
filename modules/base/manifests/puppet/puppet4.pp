# === Class base::puppet::puppet4
#
# Pins packages to the needed versions for puppet 4 and does any other needed configuration
#

class base::puppet::puppet4 {
    if os_version('debian == jessie') {
        $pin_to = 'jessie-backports'
    }
    elsif os_version('debian > jessie') {
        # Use the distro-provided package
        $pin_to = $facts['lsbdistcodename']
    }
    else {
        # no support on trusty or older distros either, at the moment
        warning('Puppet4 is still not available for this distribution')
        $pin_to = undef
    }

    if $pin_to {
        $pin_release = "release n=${pin_to}"
        apt::pin { 'puppet-all':
            pin      => $pin_release,
            package  => 'puppet*',
            priority => '1001',
        }
        apt::pin { 'facter':
            pin      => $pin_release,
            package  => 'facter',
            priority => '1001',
        }
    }
}
