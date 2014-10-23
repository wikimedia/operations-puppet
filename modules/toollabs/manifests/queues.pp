# Class: toollabs::queues
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class toollabs::queues($queues = undef) {

    gridengine::join { "queues-${::fqdn}":
        sourcedir => "${toollabs::collectors}/queues",
        list      => $queues,
    }

}

