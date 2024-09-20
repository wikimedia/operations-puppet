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
){
    include profile::ci::pipeline::publisher
    include profile::docker::engine
    include profile::java
    Class['::profile::java'] ~> Class['::jenkins']
    include ::profile::ci::thirdparty_apt
    Class['::profile::ci::thirdparty_apt'] ~> Class['::jenkins']

    class { '::jenkins':
        http_port            => $http_port,
        prefix               => $prefix,
        umask                => '0002',
        service_ensure       => $jenkins_service_ensure,
        service_enable       => $jenkins_service_enable,
        service_monitor      => $jenkins_service_monitor,
        use_scap3_deployment => true,
    }

    file { [ '/etc/jenkins/secrets', '/etc/jenkins/secrets/releasing' ]:
        ensure  => directory,
        owner   => 'jenkins',
        group   => 'jenkins',
        mode    => '0550',
        require => Class['::jenkins'],
    }

    $secrets = [
        'release_notes_bot_pass', 'integration_registry_pass',
        'releases_jenkins_rsa_pass', 'releases_jenkins_rsa_key',
        'trainbranchbot_netrc', 'jenkins_phab_conduit_token',
        'doc_rsync_pass', 'security_patch_bot_conduit_token'
    ]

    $secrets.each |$secret| {
        file { "/etc/jenkins/secrets/releasing/${secret}":
          ensure  => present,
          owner   => 'jenkins',
          group   => 'jenkins',
          mode    => '0400',
          content => secret("jenkins/releasing/${secret}"),
          require => File['/etc/jenkins/secrets/releasing'],
        }
    }

    $jenkins_restart_ensure = $jenkins_service_enable ? {
        'mask'  => 'absent',
        default => 'present',
    }

    profile::auto_restarts::service { 'jenkins':
        ensure => $jenkins_restart_ensure,
    }

    profile::auto_restarts::service { 'containerd': }
    profile::auto_restarts::service { 'docker': }

    # Controller connects to itself via the fqdn / primary IP ipaddress
    class { 'jenkins::agent':
        ssh_key => $jenkins_agent_key,
        user    => $jenkins_agent_username,
        workdir => "/srv/${jenkins_agent_username}",
    }

    class { '::releases':
        sitename         => $sitename,
        sitename_jenkins => $sitename_jenkins,
        http_port        => $http_port,
        prefix           => $prefix,
        patches_owner    => 'jenkins',
        patches_group    => '705',
    }

    httpd::site { $sitename_jenkins:
        content => template('releases/apache-jenkins.conf.erb'),
    }

    if $jenkins_service_monitor {
        prometheus::blackbox::check::http { "${sitename_jenkins}-login":
            server_name        => $sitename_jenkins,
            team               => 'collaboration-services',
            severity           => 'task',
            path               => '/login',
            ip_families        => ['ip4'],
            force_tls          => true,
            body_regex_matches => ['Jenkins'],
        }
    }
}
