# This prevents normal users who are not a member of tools.admin
# from authenticating via SSH.

class toollabs::infrastructure {

    if member(['tools', 'toolsbeta'], $::labsproject) {
        $banner = "modules/toollabs/40-${::labsproject}-infrastructure-banner.sh"
    }
    else {
        $banner = "Default ${name} banner."
    }

    motd::script { 'infrastructure-banner':
        ensure => present,
        source => "puppet:///${banner}",
    }

    # Infrastructure instances are limited to an (arbitrarily picked) local
    # service group and root.
    security::access::config { 'labs-admin-only':
        content => "-:ALL EXCEPT (${::labsproject}.admin) root:ALL\n",
    }
}
