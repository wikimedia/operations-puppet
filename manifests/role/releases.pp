class role::releases {
    system::role { 'releases': description => 'Releases webserver' }

    monitoring::service { 'http':
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

    include role::backup::host
    backup::set { 'srv-org-wikimedia': }
}

class role::releases::upload {
    class { '::releases::reprepro::upload': }
}
