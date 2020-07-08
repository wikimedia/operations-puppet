# server hosting MediaWiki releases
# https://releases.wikimedia.org/mediawiki/
class profile::releases::mediawiki (
    Stdlib::Fqdn $sitename = lookup('profile::releases::mediawiki::sitename'),
    Stdlib::Fqdn $sitename_jenkins = lookup('profile::releases::mediawiki::sitename_jenkins'),
    Stdlib::Unixpath $prefix = lookup('profile::releases::mediawiki::prefix'),
    Stdlib::Port $http_port = lookup('profile::releases::mediawiki::http_port'),
    String $server_admin = lookup('profile::releases::mediawiki::server_admin'),
    String $jenkins_agent_username = lookup('jenkins_agent_username'),
    String $jenkins_agent_key = lookup('profile::releases::mediawiki::jenkins_agent_key'),
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
        ssh_key => $jenkins_agent_key,
        user    => $jenkins_agent_username,
        workdir => '/srv/jenkins-slave',
    }

    class { '::releases':
        sitename         => $sitename,
        sitename_jenkins => $sitename_jenkins,
        http_port        => $http_port,
        prefix           => $prefix,
    }

    class { '::httpd':
        modules => ['rewrite', 'headers', 'proxy', 'proxy_http'],
    }

    httpd::site { $sitename:
        content => template('releases/apache.conf.erb'),
    }

    httpd::site { $sitename_jenkins:
        content => template('releases/apache-jenkins.conf.erb'),
    }

    monitoring::service { 'https_releases':
        description   => "HTTPS ${sitename}",
        check_command => "check_https_url!${sitename}!/",
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
        srange => "(${::ipaddress} ${::ipaddress6})",
    }

    backup::set { 'srv-org-wikimedia': }
}
