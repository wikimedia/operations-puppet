# A profile for setting up the kubernetes control-plane
class role::kubernetes::master {
    include ::profile::standard
    include ::profile::base::firewall

    # Sets up kubernetes on the machine
    include ::profile::kubernetes::master
    # Strictly speaking kubectl isn't needed, but have it here for historical
    # reasons
    include ::profile::kubernetes::client

    # Kubernetes masters are LVS backend servers
    include ::profile::lvs::realserver

    system::role { 'kubernetes::master':
        description => 'Kubernetes master server',
    }
}
