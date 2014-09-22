class swift_new::proxy::monitoring($host) {
    monitor_service { 'swift-http-frontend':
        description   => 'Swift HTTP frontend',
        check_command => "check_http_url!${host}!/monitoring/frontend",
    }
    monitor_service { 'swift-http-backend':
        description   => 'Swift HTTP backend',
        check_command => "check_http_url!${host}!/monitoring/backend",
    }
}
