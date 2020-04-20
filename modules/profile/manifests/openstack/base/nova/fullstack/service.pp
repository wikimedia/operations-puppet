class profile::openstack::base::nova::fullstack::service(
    $osstackcanary_pass = hiera('profile::openstack::base::nova::fullstack_pass'),
    $openstack_controllers = hiera('profile::openstack::base::openstack_controllers'),
    $region = hiera('profile::openstack::base::region'),
    $network = hiera('profile::openstack::base::nova::instance_network_id'),
    $puppetmaster = hiera('profile::openstack::base::puppetmaster_hostname'),
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
