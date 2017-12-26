class role::tcpircbot {

    system::role { 'tcpircbot':
        description => 'tcpircbot server',
    }

    include ::tcpircbot
    include passwords::logmsgbot

    class { '::profile::tcpircbot':
        ensure => 'present',
    }
}
