class profile::openstack::base::nova::fullstack::service(
    $osstackcanary_pass = lookup('profile::openstack::base::nova::fullstack_pass'),
    $openstack_controllers = lookup('profile::openstack::base::openstack_controllers'),
    $region = lookup('profile::openstack::base::region'),
    $network = lookup('profile::openstack::base::nova::instance_network_id'),
    $puppetmaster = lookup('profile::openstack::base::puppetmaster_hostname'),
    ) {

    # We only want this running in one place; just pick the first
    #  host in $openstack_controllers.
    class { '::openstack::nova::fullstack::service':
        active       => ($::fqdn == $openstack_controllers[0]),
        password     => $osstackcanary_pass,
        region       => $region,
        network      => $network,
        puppetmaster => $puppetmaster,
    }
    contain '::openstack::nova::fullstack::service'
}
