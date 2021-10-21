class role::ganeti_test {

    system::role { 'ganeti_test':
        description => 'Ganeti node (staging/test)',
    }

    include profile::base::production
    include profile::base::firewall

    include profile::ganeti
}
