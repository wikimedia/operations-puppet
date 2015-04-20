# == Class: role::coal
#
# This role provisions coal, a carbon-like daemon that stores Navigation
# Timing data in RRD files.
#
class role::coal {
    class { '::coal':
        endpoint => 'tcp://eventlogging.eqiad.wmnet:8600',
    }
}
