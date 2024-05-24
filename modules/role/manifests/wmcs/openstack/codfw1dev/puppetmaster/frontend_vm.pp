class role::wmcs::openstack::codfw1dev::puppetmaster::frontend_vm {
    include profile::base::production
    include profile::openstack::codfw1dev::observerenv
    include profile::openstack::codfw1dev::puppetmaster::frontend
    include profile::openstack::base::optional_firewall
    include profile::base::cloud_production
    include profile::openstack::base::puppetmaster::safe_dirs
}
