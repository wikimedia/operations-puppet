class role::swift::proxy_reporter inherits role::swift::proxy {
    system::role { 'role::swift::stats_reporter':
        description => 'swift statistics reporter',
    }
    include profile::swift::stats_reporter
}
