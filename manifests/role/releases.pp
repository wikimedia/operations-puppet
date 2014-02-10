class role::releases {
    system::role { 'releases': description => 'Releases webserver' }

    monitor_service {
        'http': description => 'HTTP',
        check_command       => 'check_http',
    }

    class { '::releases':
        sitename     => 'releases.wikimedia.org',
        docroot      => 'releases',
    }
}
