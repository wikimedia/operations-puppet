# basic role for every CloudVPS instance
class role::wmcs::instance {
    include ::profile::base::labs
    include "::profile::openstack::${::wmcs_deployment}::observerenv"
    include "::profile::openstack::${::wmcs_deployment}::clientpackages::vms"
    include "::profile::openstack::${::wmcs_deployment}::cumin::target"
    include ::profile::wmcs::instance
}
