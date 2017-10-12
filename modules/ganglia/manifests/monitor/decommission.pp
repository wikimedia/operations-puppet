class ganglia::monitor::decommission {
    package { 'ganglia-monitor':
        ensure => purged,
    }
}
