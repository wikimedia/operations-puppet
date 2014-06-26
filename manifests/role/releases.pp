class role::releases {
    system::role { 'releases': description => 'Releases webserver' }

    monitor_service { 'http':
        description     => 'HTTP',
        check_command   => 'check_http',
    }

    class { '::releases':
        sitename     => 'releases.wikimedia.org',
        docroot      => 'releases',
    }

    ferm::service { 'releases_http':
        proto => 'tcp',
        port  => '80',
    }

    ferm::service { 'releases_https':
        proto => 'tcp',
        port  => '443',
    }

}
