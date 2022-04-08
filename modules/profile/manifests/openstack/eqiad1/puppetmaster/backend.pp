class profile::openstack::eqiad1::puppetmaster::backend(
    Stdlib::Host $puppetmaster_ca = lookup('profile::openstack::eqiad1::puppetmaster::ca'),
    Hash[String, Puppetmaster::Backends] $puppetmasters = lookup('profile::openstack::eqiad1::puppetmaster::servers'),
) {
    class {'::profile::openstack::base::puppetmaster::backend':
        puppetmaster_ca => $puppetmaster_ca,
        puppetmasters   => $puppetmasters,
    }
}
