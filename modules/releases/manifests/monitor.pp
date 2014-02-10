class releases::monitor {
    monitor_service {
        'http': description => 'HTTP',
        check_command       => 'check_http',
    }
}
