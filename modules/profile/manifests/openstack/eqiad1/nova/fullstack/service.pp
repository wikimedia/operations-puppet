class profile::openstack::eqiad1::nova::fullstack::service(
    $osstackcanary_pass = lookup('profile::openstack::eqiad1::nova::fullstack_pass'),
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::eqiad1::openstack_controllers'),
    $region = lookup('profile::openstack::eqiad1::region'),
    $network = lookup('profile::openstack::eqiad1::nova::instance_network_id'),
    $puppetmaster = lookup('profile::openstack::eqiad1::puppetmaster_hostname'),
    $bastion_ip = lookup('profile::openstack::eqiad1::nova::fullstack_bastion_ip'),
    ) {

    require ::profile::openstack::eqiad1::clientpackages
    class { '::profile::openstack::base::nova::fullstack::service':
        openstack_controllers => $openstack_controllers,
        osstackcanary_pass    => $osstackcanary_pass,
        region                => $region,
        network               => $network,
        puppetmaster          => $puppetmaster,
        bastion_ip            => $bastion_ip,
        deployment            => 'eqiad1',
    }

    # We only want this running in one place; just pick the first
    #  option in the list.
    if ($::fqdn == $openstack_controllers[0]) {
        class {'::openstack::nova::fullstack::monitor':}
    }
}
