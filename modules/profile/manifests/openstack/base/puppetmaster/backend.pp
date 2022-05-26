class profile::openstack::base::puppetmaster::backend(
    Stdlib::Host $puppetmaster_ca = lookup('profile::openstack::base::puppetmaster::ca'),
    Hash[String, Puppetmaster::Backends] $puppetmasters = lookup('profile::openstack::base::puppetmaster::servers'),
) {
    include ::network::constants

    class { 'profile::openstack::base::puppetmaster::common': }

    $config = {
        'node_terminus'     => 'exec',
        'external_nodes'    => '/usr/local/bin/puppet-enc',
        'thin_storeconfigs' => false,
        'autosign'          => true,
    }

    class { '::profile::puppetmaster::backend':
        config         => $config,
        secure_private => false,
        servers        => $puppetmasters,
        ca_server      => $puppetmaster_ca,
    }
}
