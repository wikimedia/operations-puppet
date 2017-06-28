# server hosting Mediawiki releases
# https://releases.wikimedia.org/mediawiki/
class profile::releases::mediawiki {

    class { '::jenkins':
        access_log => true,
        http_port  => '8080',
        prefix     => '/jenkins',
        umask      => '0002',
    }

    class { '::releases':
        sitename => 'releases.wikimedia.org',
    }

    monitoring::service { 'http':
        description   => 'HTTP',
        check_command => 'check_http',
    }


    ferm::service { 'releases_http':
        proto => 'tcp',
        port  => '80',
    }

    backup::set { 'srv-org-wikimedia': }
}
