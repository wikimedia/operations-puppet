class role::ganeti_test {

    system::role { 'ganeti_test':
        description => 'Ganeti node (staging/test)',
    }

    include profile::standard
    include profile::base::firewall

    include profile::ganeti
}
