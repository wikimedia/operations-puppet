# Class: toollabs::infrastructure
#
# This role configures the instance as part of the infrastructure
# where endusers are not expected to log in.  This class is not intended
# to be used directly, but is included from some other classes.
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class toollabs::infrastructure {

    motd::script { 'infrastructure-banner':
        ensure => present,
        source => "puppet:///modules/toollabs/40-${::labsproject}-infrastructure-banner",
    }

    security::access { 'labs-admin-only':
        content => "-:ALL EXCEPT (${::labsproject}.admin) root:ALL\n",
    }

}
