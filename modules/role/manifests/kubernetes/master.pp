class role::kubernetes::master {
    include ::profile::standard
    include ::profile::base::firewall

    # Sets up kubernetes on the machine
    include ::profile::kubernetes::master
    include ::profile::lvs::realserver

    system::role { 'kubernetes::master':
        description => 'Kubernetes master server',
    }
}
