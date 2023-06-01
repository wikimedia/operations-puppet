class role::ganeti_test {

    system::role { 'ganeti_test':
        description => 'Ganeti node (staging/test)',
    }

    include profile::base::production
    include profile::firewall

    include profile::ganeti
}
