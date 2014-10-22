# Class: toollabs::hostgroups
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class toollabs::hostgroups($groups = undef) {

    gridengine::join { "hostgroups-${::fqdn}":
        sourcedir => "${toollabs::collectors}/hostgroups",
        list      => $goups,
    }

}

