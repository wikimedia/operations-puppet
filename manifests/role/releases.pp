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

    class { '::releases::reprepro': }

    # ssh-based uploads from tin
    ferm::service { 'tin_package_upload':
        proto => 'tcp',
        port  => '22',
        srange => '10.64.0.196/32',
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

class role::releases::upload {
    class { '::releases::reprepro::upload': }
}
