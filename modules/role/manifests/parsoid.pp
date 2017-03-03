# == Class: role::parsoid
#
# filtertags: labs-project-deployment-prep
class role::parsoid {

    include ::base::firewall

    if hiera('has_lvs', true) {
        include role::lvs::realserver
    }

    include profile::parsoid

}
