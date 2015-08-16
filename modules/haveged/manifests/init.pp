# == Class: haveged
#
# The haveged project is an attempt to provide an easy-to-use, unpredictable
# random number generator based upon an adaptation of the HAVEGE algorithm.
# Haveged was created to remedy low-entropy conditions in the Linux random
# device that can occur under some workloads, especially on headless servers.
#
class haveged {
    require_package('haveged')

    service { 'haveged':
        ensure   => running,
        enable   => true,
        provider => $::initsystem ? {
            systemd => 'systemd',
            default => 'debian',
        },
    }
}
