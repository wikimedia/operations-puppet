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
    $jenkins_agent_username = hiera('jenkins_agent_username'),
    $jenkins_agent_key = hiera('profile::releases::mediawiki::jenkins_agent_key'),
){
    class { '::jenkins':
        access_log => true,
        http_port  => $http_port,
        prefix     => $prefix,
        umask      => '0002',
    }

    base::service_auto_restart { 'jenkins': }

    # Master connect to itself via the fqdn / primary IP ipaddress
    class { 'jenkins::slave':
        ssh_key => jenkins_agent_key,
        user    => $jenkins_agent_username,
        workdir => '/srv/jenkins-slave',
    }

    class { '::releases':
        sitename         => $sitename,
        sitename_jenkins => $sitename_jenkins,
        http_port        => $http_port,
        prefix           => $prefix,
    }

    class { '::contint::composer': }
    class { '::contint::packages::php': }

    class { '::httpd':
        modules => ['rewrite', 'headers', 'proxy', 'proxy_http'],
    }

    httpd::site { $sitename:
        content => template('releases/apache.conf.erb'),
    }

    httpd::site { $sitename_jenkins:
        content => template('releases/apache-jenkins.conf.erb'),
    }

    monitoring::service { 'http_releases':
        description   => "HTTP ${sitename}",
        check_command => "check_http_url!${sitename}!/",
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Releases.wikimedia.org',
    }

    monitoring::service { 'http_releases_jenkins':
        description   => "HTTP ${sitename_jenkins}",
        check_command => "check_http_url!${sitename_jenkins}!/login",
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Releases.wikimedia.org#Jenkins',
    }

    ferm::service { 'releases_http':
        proto  => 'tcp',
        port   => '80',
        srange => '$CACHES',
    }

    backup::set { 'srv-org-wikimedia': }

    rsync::quickdatacopy { 'srv-org-wikimedia-releases':
      ensure      => present,
      auto_sync   => true,
      source_host => $active_server,
      dest_host   => $passive_server,
      module_path => '/srv/org/wikimedia/releases',
    }
}
