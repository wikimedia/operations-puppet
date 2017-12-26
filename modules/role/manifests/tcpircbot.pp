class role::tcpircbot {

    system::role { 'tcpircbot':
        description => 'tcpircbot server',
    }

    include ::tcpircbot

    class { '::profile::tcpircbot':
        ensure => 'present',
    }
}
