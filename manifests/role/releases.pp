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

    # ssh-based uploads from deployment servers
    ferm::service { 'deployment_package_upload':
        proto => 'tcp',
        port  => '22',
        srange => $deployment_servers,
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
