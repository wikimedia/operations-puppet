# server hosting Mediawiki releases
# https://releases.wikimedia.org/mediawiki/
class profile::releases::mediawiki (
    $sitename = hiera('profile::releases::mediawiki::sitename'),
    $sitename_jenkins = hiera('profile::releases::mediawiki::sitename_jenkins'),
    $prefix = hiera('profile::releases::mediawiki::prefix'),
    $http_port = hiera('profile::releases::mediawiki::http_port'),
    $server_admin = hiera('profile::releases::mediawiki::server_admin'),
    $active_server = hiera('releases_server'),
    $passive_server = hiera('releases_server_failover'),
){
    class { '::jenkins':
        access_log => true,
        http_port  => $http_port,
        prefix     => $prefix,
        umask      => '0002',
    }

    class { '::releases':
        sitename         => $sitename,
        sitename_jenkins => $sitename_jenkins,
        http_port        => $http_port,
        prefix           => $prefix,
    }

    class { '::apache::mod::rewrite': }
    class { '::apache::mod::headers': }
    class { '::apache::mod::proxy': }
    class { '::apache::mod::proxy_http': }

    apache::site { $sitename:
        content => template('releases/apache.conf.erb'),
    }

    apache::site { $sitename_jenkins:
        content => template('releases/apache-jenkins.conf.erb'),
    }

    monitoring::service { 'http':
        description   => 'HTTP',
        check_command => 'check_http',
    }

    ferm::service { 'releases_http':
        proto => 'tcp',
        port  => '80',
        srange => '$CACHE_MISC',
    }

    backup::set { 'srv-org-wikimedia': }

    rsync::quickdatacopy { 'srv-org-wikimedia-releases':
      ensure      => present,
      source_host => $active_server,
      dest_host   => $passive_server,
      module_path => '/srv/org/wikimedia/releases',
    }
}
