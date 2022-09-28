class profile::openstack::base::nova::fullstack::service(
    $osstackcanary_pass = lookup('profile::openstack::base::nova::fullstack_pass'),
    $openstack_controllers = lookup('profile::openstack::base::openstack_controllers'),
    $region = lookup('profile::openstack::base::region'),
    $network = lookup('profile::openstack::base::nova::instance_network_id'),
    $puppetmaster = lookup('profile::openstack::base::puppetmaster_hostname'),
    $bastion_ip = lookup('profile::openstack::base::nova::fullstack_bastion_ip'),
    $deployment = lookup('profile::openstack::base::nova::fullstack_deployment')
    ) {

    # We only want this running in one place; just pick the first
    #  host in $openstack_controllers.
    class { '::openstack::nova::fullstack::service':
        active       => ($::fqdn == $openstack_controllers[0]),
        password     => $osstackcanary_pass,
        region       => $region,
        network      => $network,
        puppetmaster => $puppetmaster,
        bastion_ip   => $bastion_ip,
        deployment   => $deployment,
    }
    contain '::openstack::nova::fullstack::service'
}
