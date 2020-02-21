class role::kubernetes::staging::master {
    include ::profile::standard
    include ::profile::base::firewall

    # Sets up docker on the machine
    include ::profile::kubernetes::master

    system::role { 'kubernetes::staging::master':
        description => 'Kubernetes master server (staging setup)',
    }
}
