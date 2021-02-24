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
    $jenkins_service_ensure = lookup('profile::releases::mediawiki::jenkins_service_ensure'),
    $jenkins_service_enable = lookup('profile::releases::mediawiki::jenkins_service_enable'),
    $jenkins_service_monitor = lookup('profile::releases::mediawiki::jenkins_service_monitor'),
    $jenkins_java_home = lookup('profile::releases::mediawiki::jenkins_java_home'),
    $ci_restricted_user_password = lookup('profile::releases::mediawiki::ci_restricted_user_password'),
){

    include ::profile::ci::kubernetes_config
    include ::profile::ci::pipeline::publisher
    include ::profile::docker::engine
    include ::profile::java
    Class['::profile::java'] ~> Class['::jenkins']

    class { '::helm': }

    class { '::jenkins':
        access_log      => true,
        http_port       => $http_port,
        prefix          => $prefix,
        umask           => '0002',
        service_ensure  => $jenkins_service_ensure,
        service_enable  => $jenkins_service_enable,
        service_monitor => $jenkins_service_monitor,
        java_home       => $jenkins_java_home,
    }

    $jenkins_restart_ensure = $jenkins_service_enable ? {
        'mask'  => 'absent',
        default => 'present',
    }

    base::service_auto_restart { 'jenkins':
        ensure => $jenkins_restart_ensure,
    }

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

    httpd::site { $sitename_jenkins:
        content => template('releases/apache-jenkins.conf.erb'),
    }

    if $jenkins_service_monitor {
        monitoring::service { 'http_releases_jenkins':
            description   => "HTTP ${sitename_jenkins}",
            check_command => "check_http_url!${sitename_jenkins}!/login",
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Releases.wikimedia.org#Jenkins',
        }
    }

    file { '/root/.docker':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0440',
    }

    file { '/root/.docker/config.json':
        content => template('releases/docker_config.json.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0440',
        require => File['/root/.docker']
    }
}
