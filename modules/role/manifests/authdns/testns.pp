# For deploying the basic software config without participating in the full
# role for e.g. public addrs, monitoring, authdns-update, etc.
class role::authdns::testns {
    include role::authdns::data
    class { 'authdns':
        monitoring         => false,
        lvs_services       => hiera('lvs::configuration::lvs_services'),
        discovery_services => hiera('discovery::services'),
    }
}
