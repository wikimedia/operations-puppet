class ganglia::monitor::decommission {
    package { 'ganglia-monitor':
        ensure => absent,
    }
}
