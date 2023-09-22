# Nova hypervisors with local storage for instance storage (not ceph)
# Most of the differences (if not all) will come from hiera parameters
# see role/eqiad/wmcs/openstack/eqiad1/virt.yaml
class role::wmcs::openstack::eqiad1::virt {
    system::role { $name: }
    include profile::base::production
    # include profile::firewall
    include profile::base::cloud_production

    # To be enabled once cloudvirt-wdqs have been moved to a WMCS-dedicated rack. (T346948)
    unless $::facts['networking']['hostname'] in ['cloudvirt-wdqs1001', 'cloudvirt-wdqs1002', 'cloudvirt-wdqs1003'] {
        include profile::wmcs::cloud_private_subnet
    }

    include profile::cloudceph::client::rbd_libvirt
    include profile::openstack::eqiad1::clientpackages
    include profile::openstack::eqiad1::envscripts
    include profile::openstack::eqiad1::nova::common
    include profile::openstack::eqiad1::nova::compute::service
    include profile::openstack::eqiad1::observerenv
    include profile::cloudceph::auth::deploy
}
