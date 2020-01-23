# basic role for every CloudVPS instance
class role::wmcs::instance {
    include ::profile::standard
    include ::profile::base::labs
    include "::profile::openstack::${::wmcs_deployment}::observerenv"
    # TODO: if required, introduce per-deployment profiles for the next 2:
    include ::profile::openstack::eqiad1::clientpackages::vms
    include ::profile::openstack::eqiad1::cumin::target
    include ::profile::wmcs::instance
}
