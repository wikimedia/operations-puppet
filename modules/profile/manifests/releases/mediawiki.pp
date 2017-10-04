# server hosting Mediawiki releases
# https://releases.wikimedia.org/mediawiki/
class profile::releases::mediawiki (
    $active_server = hiera('releases_server'),
    $passive_server = hiera('releases_server_failover'),
){
    class { '::jenkins':
        access_log => true,
        http_port  => '8080',
        prefix     => '/ci',
        umask      => '0002',
    }

    class { '::releases::proxy_jenkins':
        http_port => '8080',
        prefix    => '/ci',
    }

    class { '::releases':
        sitename         => 'releases.wikimedia.org',
        sitename_jenkins => 'releases-jenkins.wikimedia.org',
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

    rsync::quickdatacopy { 'srv-org-wikimedia-releases':
      ensure      => present,
      source_host => $active_server,
      dest_host   => $passive_server,
      module_path => '/srv/org/wikimedia/releases',
    }
}
