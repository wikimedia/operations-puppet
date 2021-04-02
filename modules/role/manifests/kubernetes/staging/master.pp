# A profile for setting up the kubernetes control-plane
class role::kubernetes::staging::master {
    include ::profile::standard
    include ::profile::base::firewall

    # Sets up kubernetes on the machine
    include ::profile::kubernetes::master
    # Strictly speaking kubectl isn't needed, but have it here for historical
    # reasons
    include ::profile::kubernetes::client

    system::role { 'kubernetes::staging::master':
        description => 'Kubernetes master server (staging setup)',
    }
}
