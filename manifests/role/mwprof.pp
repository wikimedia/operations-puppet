# == Class: role::mwprof
#
# Sets up mwprof.
#
class role::mwprof {
    class { '::mwprof':
        carbon_host    => 'graphite-in.eqiad.wmnet',
        collector_port => 3811,
    }
}
