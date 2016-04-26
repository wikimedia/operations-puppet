class icinga::monitor::stream {

    @monitoring::host { 'stream.wikimedia.org':
        host_fqdn => 'stream.wikimedia.org',
    }

    monitoring::service { 'stream_clients':
        description   => 'HTTPS stream.wikimedia.org',
        check_command => 'check_ssl_http!stream.wikimedia.org',
        host          => 'stream.wikimedia.org',
        contact_group => 'admins',
    }

}
