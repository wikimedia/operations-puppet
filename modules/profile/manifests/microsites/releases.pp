class profile::microsites::releases {
    include ::base::firewall

    monitoring::service { 'http':
        description   => 'HTTP',
        check_command => 'check_http',
    }

    class { '::releases':
        sitename => 'releases.wikimedia.org',
    }

    class { '::jenkins':
        access_log => true,
        http_port  => '8080',
        prefix     => '/jenkins',
        umask      => '0002',
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

    include ::profile::backup::host
    backup::set { 'srv-org-wikimedia': }
}
