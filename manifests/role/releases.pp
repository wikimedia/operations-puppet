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
    ferm::rule { 'deployment_package_upload':
        ensure => present,
        rule   => 'proto tcp dport ssh saddr $DEPLOYMENT_HOSTS ACCEPT;',
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
