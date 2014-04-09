# == Class: role::mwprof
#
# Sets up mwprof.
#
class role::mwprof {
    class { '::mwprof':
        collector_port => 3811,
    }
}
