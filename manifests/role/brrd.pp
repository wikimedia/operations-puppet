# == Class: role::brrd
#
# This role provisions brrd, a carbon-like daemon that stores Navigation
# Timing data in RRD files.
#
class role::brrd {
    class { '::brrd':
        endpoint => 'tcp://eventlogging.eqiad.wmnet:8600',
    }
}
