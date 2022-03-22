# == Class profile::icinga::performance
#
# Performance tweaks for the Icinga host.

class profile::icinga::performance {

    interface::rps {
        $facts['interface_primary']:
    }

}
