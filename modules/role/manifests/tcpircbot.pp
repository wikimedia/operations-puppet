class role::tcpircbot {

    system::role { 'tcpircbot':
        description => 'tcpircbot server',
    }

    include ::profile::tcpircbot
}
